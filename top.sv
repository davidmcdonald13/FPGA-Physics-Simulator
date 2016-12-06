// NOTE: clocking wizard can only create 161.905 MHz
// will this become an issue?
module top
   #(parameter SPRITES=2, DIMENSIONS=2, WIDTH=32)
   (input logic BTND, BTNU, BTNL,
    input logic CLK100MHZ,
    output logic [15:0] LED,
    output logic VGA_HS, VGA_VS,
    output logic [3:0] VGA_R, VGA_B, VGA_G);
    
    logic clk_out1, locked;
    logic [62:0][62:0] sprite;
    logic [SPRITES-1:0][10:0] sprite_row;
    logic [SPRITES-1:0][11:0] sprite_col;
    logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] init_locations, init_velos, locations, velos;
    logic [SPRITES-1:0][WIDTH/2-1:0] masses;
    logic [SPRITES-1:0][6:0] radii;
    
//    assign init_locations[0] = {64'h0, 64'h0};
    assign init_locations[0] = {32'h0100_0000, 32'h0100_0000};
    assign init_locations[1] = {32'hff00_0000, 32'hff00_0000};
    // assign init_locations = 'd0;
    assign init_velos[0] = {32'h0000_0100, 32'h0};
    assign init_velos[1] = {32'h0000_0100, 32'h0};
    assign masses = {16'h400, 16'h400};//, 64'h4_0000_0000};
    assign radii = {7'd15, 7'd15};//, 7'd15};
        
    clk_wiz_0 clk(.CLK100MHZ(CLK100MHZ), .clk_out1(clk_out1), .reset(BTND), .locked(locked));

    VGA_driver #(SPRITES) vga(.clock_162(clk_out1), .rst(BTND), .HSYNC(VGA_HS),
                        .VSYNC(VGA_VS), .RED(VGA_R), .GREEN(VGA_G), .BLUE(VGA_B),
                        .sprite(sprite), .sprite_row(sprite_row), .sprite_col(sprite_col));
                   
    sprite_generator sg(.sprite(sprite));
        
    physics_engine #(SPRITES, WIDTH, DIMENSIONS) pe(clk_out1, ~BTND, BTNU, init_locations, init_velos,
        masses, radii, locations, BTNL);
        
    locations_to_centers #(SPRITES, WIDTH) ltc(locations, sprite_row, sprite_col);
    
    always_ff @(posedge clk_out1) begin
        if (BTND) begin
            LED <= 'd0;
        end
        else begin
            LED <= LED | locations[0][0][15:0] | locations[0][0][31:16]
                       | locations[0][1][15:0] | locations[0][1][31:16];
        end
    end

endmodule: top