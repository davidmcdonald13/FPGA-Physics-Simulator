// NOTE: clocking wizard can only create 161.905 MHz
// will this become an issue?
module top
   (input logic BTND,
    input logic CLK100MHZ,
    output logic VGA_HS, VGA_VS,
    output logic [3:0] VGA_R, VGA_B, VGA_G);
    
    logic clk_out1, locked;
    
    clk_wiz_0 clk(.CLK100MHZ(CLK100MHZ), .clk_out1(clk_out1), .reset(BTND), .locked(locked));

    VGA_driver vga(.clock_162(clk_out1), .rst(BTND), .HSYNC(VGA_HS),
                   .VSYNC(VGA_VS), .RED(VGA_R), .GREEN(VGA_G), .BLUE(VGA_B));

endmodule: top
