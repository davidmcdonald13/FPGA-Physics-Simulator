module collision_handler
  #(parameter SPRITES=9, DIMENSIONS=2, WIDTH=32)
   (input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
    input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] velocities,
    input logic [SPRITES-1:0][WIDTH-1:0] 			  masses,
    input logic [SPRITES-1:0][SPRITES-1:0] 		  collision,
    output logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] new_velocities);

   logic [WIDTH-1:0] 					  mass_sum;
   logic [WIDTH-1:0] 					  mass_difference;
   logic [(2*WIDTH)+1:0] 				  v1x,v1y,v2x,v2y;
   logic [(2*WIDTH)+1:0] 				  d;
   logic [WIDTH-1:0] 					  dx,dy;

   always_comb begin
      for (integer i=0;i<SPRITES;i=i+1) begin
	 for(integer j=0;j<SPRITES;j=j+1)begin
	    mass_sum = masses[i]+masses[j];
	    dx = locations[i][0]-locations[j][0];
	    dy = locations[i][1]-locations[j][1];
	    if(collision[i][j]==0) begin
	       new_velocities[i] = velocities[i];
	       new_velocities[j] = velocities[j];
	    end
	    else begin
	       new_velocities[i][0]=velocities[i][0]-((((2*masses[j])/mass_sum)*(velocities[i][0]-velocities[j][0])*(dx))/d);
	       new_velocities[j][0]=velocities[j][0]-((((2*masses[i])/mass_sum)*(velocities[j][0]-velocities[i][0])*(-dx))/d);
	       new_velocities[i][1]=velocities[i][1]-((((2*masses[j])/mass_sum)*(velocities[i][1]-velocities[j][1])*(dy))/d);
	       new_velocities[j][1]=velocities[j][1]-((((2*masses[i])/mass_sum)*(velocities[j][1]-velocities[i][1])*(-dy))/d);
	    end
	 end // for (j=0;j<SPRITES;j=j+1)
      end // for (i=0;i<SPRITES;i=i+1)
   end // always_comb
   
endmodule: collision_handler
	    
module collision_detector
    #(parameter SPRITES=9, DIMENSIONS=2, WIDTH=32)
    (input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
        velocities,
    input logic [SPRITES-1:0][WIDTH-1:0] masses,
    input logic [SPRITES-1:0][6:0] radii,
    output logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] new_locations,
        new_velocities);

   logic [SPRITES-1:0][SPRITES-1:0] 			  collision;	
   logic [(2*WIDTH)+1:0] 		  d;
   logic [WIDTH-1:0] 			  dx, dy;
   logic [13:0] 				  r;

   collision_handler c0(locations,velocities,masses,collision,new_velocities);
   always_comb begin
      for (integer i=0;i<SPRITES;i++) begin
	 for (integer j=0;j<SPRITES;j++) begin
	    dx = locations[i][0]-locations[j][0];
	    dy = locations[i][1]-locations[j][1];
	    d = (dx*dx)+(dy*dy);
	    r = (radii[i]+radii[j])*(radii[i]+radii[j]);
	    if (i==j) collision[i][j] = 0;
	    else begin
	       if (d <= r) collision[i][j] = 1;
	       else collision[i][j] = 0;
	    end
	 end // for (j=0;j<SPRITES;j++)
      end // for (i=0;i<SPRITES;i++)
   end
	    
endmodule: collision_detector
