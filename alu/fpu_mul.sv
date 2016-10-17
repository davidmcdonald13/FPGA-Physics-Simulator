`define F 15
`define R 30-F
`define S 31

module fpu_mul
  (input logic [31:0] a, b,
   output logic [63:0] result);

   logic [R:0] 	       r_a, r_b;
   logic [F-1:0]       f_a, f_b;
   logic [2*R:0]       r_res;
   logic [2*F:0]       f_res;

   assign result[63] = a[S] ^ b[S];

   always_comb begin
      r_res = r_a*r_b;
      f_res = f_a*f_b;
   end

endmodule: fpu_mult


      
