// 1600 x 1200 monitor
// Standards taken from tinyvga.com/vga-timing/1600x1200@60Hz

module range_check
   #(parameter WIDTH=4)
   (input  logic [WIDTH-1:0] val, low, high,
    output logic in_range);
    
    assign in_range = (val >= low) && (val <= high);
    
endmodule: range_check

module color_lookup
   #(parameter SPRITES=1)
   (input logic [62:0][62:0] sprite,
    input logic [SPRITES-1:0][10:0] sprite_row,
    input logic [10:0] row,
    input logic [SPRITES-1:0][11:0] sprite_col,
    input logic [11:0] col,
    output logic [3:0] red, green, blue);
    
    logic[SPRITES-1:0] index;
    
    always_comb begin
        red = index[0] ? 4'hf : 4'd0;
        blue = index[2] ? 4'hf : 4'd0;
        green = index[1] ? 4'hf : 4'd0;
        if (index[3]) begin
            red = 4'hf;
            blue = 4'hf;
            green = 4'hf;
         end
    end
    
    genvar i;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            always_comb begin
                index[i] = 0;
                if ((sprite_col[i] < 12'd31 || col >= sprite_col[i] - 12'd31) && col <= sprite_col[i] + 12'd31) begin
                    if ((sprite_row[i] < 11'd31 || row >= sprite_row[i] - 11'd31) && row <= sprite_row[i] + 11'd31) begin
                        index[i] = sprite[row - sprite_row[i] + 11'd31][col - sprite_col[i] + 12'd31];
                    end
                end
            end
        end
    endgenerate
    
endmodule: color_lookup 

module VGA_driver
   #(parameter SPRITES=1)
   (input logic clock_162, rst,
    input logic [62:0][62:0] sprite,
    input logic [SPRITES-1:0][10:0] sprite_row,
    input logic [SPRITES-1:0][11:0] sprite_col,
    output logic [3:0] RED, GREEN, BLUE,
    output logic HSYNC, VSYNC);

    logic [11:0] col, next_col;
    logic [10:0] row, next_row;
    logic [3:0] red_value, green_value, blue_value;
    logic        hor_visible, vert_visible;
    logic        HS_l, VS_l;

    range_check #(12) hsync(col, 12'd64, 12'd255, HS_l);
    range_check #(11) vsync(row, 11'd1, 11'd3, VS_l);

    range_check #(12) hv(col, 12'd560, 12'd2159, hor_visible);
    range_check #(11) vv(row, 11'd50, 11'd1249, vert_visible);
    
    color_lookup #(SPRITES) cl(.sprite(sprite), .red(red_value), .green(green_value), .blue(blue_value),
                    .sprite_row(sprite_row), .sprite_col(sprite_col), .row(row - 11'd50), .col(col - 12'd560));
   
    assign HSYNC = ~HS_l;
    assign VSYNC = ~VS_l;
    
    always_comb begin
        RED = (hor_visible & vert_visible) ? red_value : 4'd0;
        BLUE = (hor_visible & vert_visible) ? blue_value : 4'd0;
        GREEN = (hor_visible & vert_visible) ? green_value : 4'd0;
    end 

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
