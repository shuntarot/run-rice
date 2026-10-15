//! The smallest program: one line on the console, then exit status 0.

#![no_std]
#![no_main]

use rice_bsp::{entry, exit, println};

#[entry]
fn main() -> ! {
    println!("hello from rice");
    exit(0)
}
