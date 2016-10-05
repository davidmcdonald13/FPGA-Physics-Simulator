// NOTE: clocking wizard can only create 161.905 MHz
// will this become an issue?
module top
   (input logic BTND,
    input logic CLK100MHZ,
    input logic [5:0] SW, 
    output logic VGA_HS, VGA_VS,
    output logic [3:0] VGA_R, VGA_B, VGA_G);
    
    logic clk_out1, locked;
    logic [126:0][126:0] sprite;
    logic [3:0][10:0] sprite_row;
    logic [3:0][11:0] sprite_col;
    
    assign sprite_row = {11'd0, 11'd0, 11'd1200,  11'd1200};
    assign sprite_col = {12'd0, 12'd1600, 12'd0, 12'd1600};
    
    clk_wiz_0 clk(.CLK100MHZ(CLK100MHZ), .clk_out1(clk_out1), .reset(BTND), .locked(locked));

    VGA_driver vga(.clock_162(clk_out1), .rst(BTND), .HSYNC(VGA_HS),
                   .VSYNC(VGA_VS), .RED(VGA_R), .GREEN(VGA_G), .BLUE(VGA_B),
                   .sprite(sprite), .sprite_row(sprite_row), .sprite_col(sprite_col));
                   
    sprite_generator sg(.radius(SW), .sprite(sprite));

endmodule: top
