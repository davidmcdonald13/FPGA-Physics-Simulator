module location_to_pixels
   #(parameter WIDTH=32)
   (input logic [1:0][WIDTH-1:0] dimensions,
    output logic [11:0] col,
    output logic [10:0] row);

    logic [WIDTH/2-1:0] row_int, rounded_row_int, col_int, rounded_col_int;

    assign col_int = dimensions[0][WIDTH-1:WIDTH/2] + 'd800;
    assign row_int = dimensions[1][WIDTH-1:WIDTH/2] + 'd600;

    always_comb begin
        if (col_int[WIDTH/2-1:12] == 'd0)
            col = col_int[11:0];
        else
            col = 'd1700;
        if (row_int[WIDTH/2-1:11] == 'd0)
            row = row_int[10:0];
        else row = 'd1300;
    end


endmodule: location_to_pixels

module locations_to_centers
   #(parameter SPRITES=9, WIDTH=32)
   (input logic [SPRITES-1:0][1:0][WIDTH-1:0] locations,
    output logic [SPRITES-1:0][10:0] rows,
    output logic [SPRITES-1:0][11:0] cols);
    
    genvar i;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            location_to_pixels #(WIDTH) ltp(locations[i], cols[i], rows[i]);
        end
    endgenerate
endmodule: locations_to_centers
