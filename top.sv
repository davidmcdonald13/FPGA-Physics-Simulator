// NOTE: clocking wizard can only create 161.905 MHz
// will this become an issue?
module top
   (input logic BTND,
    input logic CLK_162,
    output logic HYSNC, VSYNC,
    output logic RED0, RED1, RED2, RED3,
    output logic BLU0, BLU1, BLU2, BLU3,
    output logic GRN0, GRN1, GRN2, GRN3);

    logic [3:0] red, green, blue;

    assign red = {RED3, RED2, RED1, RED0};
    assign green = {GRN3, GRN2, GRN1, GRN0};
    assign blue = {BLU3, BLU2, BLU1, BLU0};

    VGA_driver vga(.clock_162(CLK_162), .rst(BTND), .HSYNC(HSYNC),
                   .VSYNC(VSYNC), .RED(red), .GREEN(green), .BLUE(blue));

endmodule: top
