// Runs asm/smoke.elf on rice_top. Both memories behave like the harness's
// FPGA memory: one cycle, byte addressed, 64 KB from BASE.
module tb;
    logic clk = 0;
    always #5 clk = ~clk;

    logic [31:0] ia, ird, da, dwd, drd;
    logic        ire, dre, dwe;
    logic [3:0]  dws;
    localparam logic [31:0] BASE = 32'h8000_0000;  // dut_base in Harness.toml
    logic [31:0] imem [0:16383];
    logic [31:0] dmem [0:16383];
    logic [31:0] want [0:8];

    logic [31:0] cycle = 0;
    logic        rst_n;
    integer      oor = 0, bad = 0, i;
    logic [31:0] count;

    assign rst_n = cycle >= 5;

    run_rice_rice_top dut (
        .i_clk(clk), .i_rst(rst_n),
        .o_imem_addr(ia), .o_imem_re(ire), .i_imem_rdata(ird),
        .o_dmem_addr(da), .o_dmem_re(dre), .o_dmem_we(dwe),
        .o_dmem_wstrb(dws), .o_dmem_wdata(dwd), .i_dmem_rdata(drd)
    );

    always @(posedge clk) begin
        if (ire) begin
            ird <= ia - BASE < 65536 ? imem[ia[15:2]] : 0;
            if (ia - BASE >= 65536) oor <= oor + 1;
        end
        if (dre) begin
            drd <= da - BASE < 65536 ? dmem[da[15:2]] : 0;
            if (da - BASE >= 65536) oor <= oor + 1;
        end
        if (dwe) begin
            if (da - BASE < 65536) begin
                if (dws[0]) dmem[da[15:2]][7:0]   <= dwd[7:0];
                if (dws[1]) dmem[da[15:2]][15:8]  <= dwd[15:8];
                if (dws[2]) dmem[da[15:2]][23:16] <= dwd[23:16];
                if (dws[3]) dmem[da[15:2]][31:24] <= dwd[31:24];
            end else begin
                oor <= oor + 1;
            end
        end
    end

    initial begin
        for (i = 0; i < 16384; i = i + 1) begin
            imem[i] = 0;
            dmem[i] = 0;
        end
        $readmemh("smoke.hex", imem);
        $readmemh("smoke.hex", dmem);

        // What asm/smoke.S writes at 0x8000_1000, word by word.
        want[0] = 32'h21534e48; want[1] = 32'h40101110; want[2] = 32'h00000000;
        want[3] = 32'hc0ffee42; want[4] = 32'h000f45f6; want[5] = 32'h44332211;
        want[6] = 32'h66665555; want[7] = 32'h12345678; want[8] = 32'h12345678;
    end

    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (cycle == 3000) begin
            for (i = 0; i < 9; i = i + 1) begin
                if (dmem[1024 + i] == want[i]) begin
                    $display("+%h %h", 8'(i * 4), dmem[1024 + i]);
                end else begin
                    $display("+%h %h  <- want %h", 8'(i * 4), dmem[1024 + i], want[i]);
                    bad = bad + 1;
                end
            end
            count = dmem[1024 + 9];
        end
        if (cycle == 3300) begin
            $display("+24 %h -> %h", count, dmem[1024 + 9]);
            if (dmem[1024 + 9] == count) bad = bad + 1;
            if (oor != 0) begin
                $display("%0d accesses out of range", oor);
                bad = bad + 1;
            end
            if (bad == 0) $display("PASS");
            else $display("FAIL");
            $finish;
        end
    end
endmodule
