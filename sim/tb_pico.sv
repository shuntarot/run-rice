// Runs picoruby/picoruby.elf on rice_mem_top, with 1 MB of dmem, and prints
// what the program wrote to its RTT console (`+cb=<address of the RTT block>`).
// tcm behaves like the harness's FPGA memory: one cycle, byte addressed,
// 64 KB from BASE. dmem is an AXI4 memory from DRAM_BASE whose channels stall
// for a varying number of cycles, the way DRAM behind a clock crossing does.
module tb;
    logic clk = 0;
    always #5 clk = ~clk;

    logic [31:0] ta, trd, twd;
    logic        tre, twe;
    logic [3:0]  tws;
    // dut_base in Harness.toml
    localparam logic [31:0] BASE      = 32'h8000_0000;
    localparam logic [31:0] DRAM_BASE = 32'h8001_0000;
    logic [31:0] tcm  [0:16383];
    logic [31:0] dmem [0:262143];

    logic [31:0] cycle = 0;
    logic        rst_n;
    integer      stalls = 0, oor = 0, bad = 0, i;
    logic [31:0] count;

    assign rst_n = cycle >= 5;

    __std___axi4_if____std___axi4_pkg__32__4__1__1__1__1__1__1 axi ();

    run_rice_rice_mem_top dut (
        .i_clk(clk), .i_rst(rst_n),
        .o_tcm_addr(ta), .o_tcm_re(tre), .o_tcm_we(twe), .o_tcm_wstrb(tws),
        .o_tcm_wdata(twd), .i_tcm_rdata(trd),
        .dmem(axi.master)
    );

    // Pseudo-random ready and response delays, so AW and W are taken in
    // either order and R / B come back late.
    logic [15:0] lfsr = 16'hace1;
    always @(posedge clk) lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

    logic        aw_got, w_got, ar_got;
    logic [31:0] aw_addr, ar_addr;  // offsets from DRAM_BASE, as the harness makes them
    logic [31:0] w_data;
    logic [3:0]  w_strb;
    logic [2:0]  r_wait, b_wait;

    assign axi.awready = rst_n && !aw_got && lfsr[0];
    assign axi.wready  = rst_n && !w_got && lfsr[1];
    assign axi.arready = rst_n && !ar_got && lfsr[2];
    assign axi.bvalid  = aw_got && w_got && b_wait == 0;
    assign axi.bresp   = __std_axi4_config::resp_variants_OKAY;
    assign axi.bid     = 0;
    assign axi.buser   = 0;
    assign axi.rvalid  = ar_got && r_wait == 0;
    assign axi.rdata   = ar_addr < 1048576 ? dmem[ar_addr[19:2]] : 0;
    assign axi.rresp   = __std_axi4_config::resp_variants_OKAY;
    assign axi.rid     = 0;
    assign axi.rlast   = 1;
    assign axi.ruser   = 0;

    // The bridge sends single whole-word beats only.
    function automatic logic odd(logic [2:0] size, logic [7:0] len, logic [1:0] low);
        return size != 3'd2 || len != 0 || low != 0;
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            aw_got <= 0;
            w_got  <= 0;
            ar_got <= 0;
            r_wait <= 0;
            b_wait <= 0;
        end else begin
            if (axi.awvalid && axi.awready) begin
                aw_got  <= 1;
                aw_addr <= axi.awaddr - DRAM_BASE;
                b_wait  <= lfsr[5:3];
                if (odd(axi.awsize, axi.awlen, axi.awaddr[1:0])) bad = bad + 1;
            end
            if (axi.wvalid && axi.wready) begin
                w_got  <= 1;
                w_data <= axi.wdata;
                w_strb <= axi.wstrb;
                if (!axi.wlast) bad = bad + 1;
            end
            if (axi.arvalid && axi.arready) begin
                ar_got  <= 1;
                ar_addr <= axi.araddr - DRAM_BASE;
                r_wait  <= lfsr[8:6];
                if (odd(axi.arsize, axi.arlen, axi.araddr[1:0])) bad = bad + 1;
            end
            if (aw_got && w_got && b_wait != 0) b_wait <= b_wait - 1;
            if (ar_got && r_wait != 0) r_wait <= r_wait - 1;

            if (axi.bvalid && axi.bready) begin
                aw_got <= 0;
                w_got  <= 0;
                if (aw_addr < 1048576) begin
                    if (w_strb[0]) dmem[aw_addr[19:2]][7:0]   <= w_data[7:0];
                    if (w_strb[1]) dmem[aw_addr[19:2]][15:8]  <= w_data[15:8];
                    if (w_strb[2]) dmem[aw_addr[19:2]][23:16] <= w_data[23:16];
                    if (w_strb[3]) dmem[aw_addr[19:2]][31:24] <= w_data[31:24];
                end else begin
                    oor <= oor + 1;
                end
            end
            if (axi.rvalid && axi.rready) begin
                ar_got <= 0;
                if (ar_addr >= 1048576) oor <= oor + 1;
            end
            // One transfer at a time: a read and a write never overlap.
            if ((aw_got || w_got) && ar_got) bad = bad + 1;
        end
    end

    integer cb, n, rd, wr, tbuf;
    logic [31:0] max_cycles = 200_000_000;
    initial if ($value$plusargs("max=%d", max_cycles)) ;

    function automatic logic [31:0] dword(input logic [31:0] a);
        return dmem[(a - DRAM_BASE) >> 2];
    endfunction

    initial begin
        for (i = 0; i < 16384; i = i + 1) tcm[i] = 0;
        for (i = 0; i < 262144; i = i + 1) dmem[i] = 0;
        $readmemh("pico_tcm.hex", tcm);
        $readmemh("pico_dmem.hex", dmem);
        if (!$value$plusargs("cb=%h", cb)) begin
            $display("give +cb=<address of the RTT block>");
            $finish;
        end
    end

    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (rst_n && (tre || twe) && ta - BASE >= 65536) oor <= oor + 1;
        if (tre) trd <= tcm[ta[15:2]];
        if (twe) begin
            if (tws[0]) tcm[ta[15:2]][7:0]   <= twd[7:0];
            if (tws[1]) tcm[ta[15:2]][15:8]  <= twd[15:8];
            if (tws[2]) tcm[ta[15:2]][23:16] <= twd[23:16];
            if (tws[3]) tcm[ta[15:2]][31:24] <= twd[31:24];
        end
    end

    // The block is: id[16], max_up, max_down, then 24-byte buffers (name,
    // tbuf, size, wr, rd, flags). Up 1 is the exit channel.
    // The last reads and writes that reached DRAM, for finding where a hung
    // program is.
    logic [31:0] last_ar [0:15], last_aw [0:15];
    integer ar_n = 0, aw_n = 0;
    always @(posedge clk) begin
        if (axi.arvalid && axi.arready) begin last_ar[ar_n % 16] <= axi.araddr; ar_n <= ar_n + 1; end
        if (axi.awvalid && axi.awready) begin last_aw[aw_n % 16] <= axi.awaddr; aw_n <= aw_n + 1; end
    end

    integer printed = 0;
    always @(posedge clk) if (cycle[9:0] == 0 && rst_n) begin
        if (dword(cb) == 32'h47474553 && dword(cb + 24 + 24 + 12) != 0) begin
            // Terminal, from the start up to wr (the buffer is large enough here)
            tbuf = dword(cb + 24 + 4);
            wr  = dword(cb + 24 + 12);
            for (n = printed; n < wr; n = n + 1)
                $write("%c", dword(tbuf + (n & ~3)) >> (8 * (n & 3)));
            printed = wr;
            $display("\nexit status %0d after %0d cycles, %0d accesses out of range, %0d bad",
                     dword(dword(cb + 24 + 24 + 4)) & 32'hff, cycle, oor, bad);
            $finish;
        end else if (cycle > max_cycles) begin
            $display("timeout after %0d cycles; rtt id %h, terminal wr %0d", cycle,
                     dword(cb), dword(cb + 24 + 12));
            tbuf = dword(cb + 24 + 4);
            wr   = dword(cb + 24 + 12);
            for (n = 0; n < wr && n < 2000; n = n + 1)
                $write("%c", dword(tbuf + (n & ~3)) >> (8 * (n & 3)));
            $display("");
            $display("%0d reads, %0d writes reached DRAM; the last of each:", ar_n, aw_n);
            for (n = 0; n < 16; n = n + 1)
                $display("  read %h   write %h", last_ar[n], last_aw[n]);
            $finish;
        end
    end
endmodule
