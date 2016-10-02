// 1600 x 1200 monitor
// Standards taken from tinyvga.com/vga-timing/1600x1200@60Hz

module range_check
   #(parameter WIDTH=4)
   (input  logic [WIDTH-1:0] val, low, high,
    output logic in_range);
    
    assign in_range = (val >= low) && (val <= high);
    
endmodule: range_check

module pixelArray
   (input  logic [11:0] col,
    input  logic [10:0] row,
    output logic [3:0] red, blue, green);
    
    always_comb begin
        red = 4'd0;
        blue = 4'd0;
        green = 4'd0;
        if (row < 11'd300) begin
            red = 4'hf;
        end
        else if (row < 11'd600) begin
            blue = 4'hf;
        end
        else if (row < 11'd900) begin
            green = 4'hf;
        end
        else begin
            red = 4'hf;
            blue = 4'hf;
            red = 4'hf;
        end
    end
endmodule: pixelArray

module VGA_driver
   (input logic clock_162, rst,
    output logic [3:0] RED, GREEN, BLUE,
    output logic HSYNC, VSYNC);

    logic [11:0] col, next_col;
    logic [10:0] row, next_row;
    logic [3:0] red_value, green_value, blue_value;
    logic        hor_visible, vert_visible;//, visible;
    logic        HS_l, VS_l;

    range_check #(12) hsync(col, 12'd64, 12'd255, HS_l);
    range_check #(11) vsync(row, 11'd1, 11'd3, VS_l);

    range_check #(12) hv(col, 12'd560, 12'd2159, hor_visible);
    range_check #(11) vv(row, 11'd50, 11'd1249, vert_visible);
    
    pixelArray pa(.col(col - 12'd560), .row(row - 11'd50), .red(red_value), .green(green_value), .blue(blue_value));
    /*assign red_value = 4'hf;
    assign blue_value = 4'hf;
    assign green_value = 4'hf;*/

    //assign visible = hor_visible & vert_visible;
    assign HSYNC = ~HS_l;
    assign VSYNC = ~VS_l;
    
    assign RED = (hor_visible & vert_visible) ? red_value : 4'd0;
    assign BLUE = (hor_visible & vert_visible) ? blue_value : 4'd0;
    assign GREEN = (hor_visible & vert_visible) ? green_value : 4'd0; 

    always_comb begin
        if (col == 12'd2159) begin
            if (row == 11'd1249)
                next_row = 0;
            else
                next_row = row + 1;
            next_col = 0;
        end
        else begin
            next_row = row;
            next_col = col + 1;
        end
    end

    always_ff @(posedge clock_162) begin
        // NEXYS 4 buttons are HIGH when pushed
        if (rst) begin
            row <= 0;
            col <= 0;
        end
        else begin
            row <= next_row;
            col <= next_col;
        end
    end

endmodule: VGA_driver
