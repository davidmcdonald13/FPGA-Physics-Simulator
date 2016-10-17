`define F 'd15 //number of floating point bits
`define R 'd30 - F //'regular' bits
`define S 'd31 //sign bit

//f_a = decimal part of inputA
//f_b = decimal part of inputB
//r_a = 'regular' part of inputA
//r_b = 'regular' part of inputB
//f_res = decimal part of result
//r_res = 'regular' part of result

module fpu_add //computes a+b 
  (input logic [31:0] a, b,
   output logic [31:0] result);

   logic [F-1:0] 	       f_a, f_b, f_res;
   logic [R:0] 	       r_a, r_b, r_res;
   logic 	       neg_a, neg_b;
   logic 	       fp_carry; //indicates if the fp op generated a carry 
   logic 	       s_res; //sign bit of the result
   
   assign neg_a = a[S] ? 1:0;
   assign neg_b = b[S] ? 1:0;
   assign result = {s_res, r_res, f_res};
 
   always_comb begin
      case({neg_a, neg_b}) begin
	 2'b00: begin
	    f_res = f_a + f_b;
	    r_res = r_a + r_b;
	    s_res = 0;
	    if(f_a != 0 && f_b != 0 && f_res == 0)
	      fp_carry = 1;
	    else
	      fp_carry = 0;
	    r_res = fp_carry ? r_res + 'd1 : r_res;
	 end
	2'b01: begin
	   fp_carry = 0;
	   if (r_a >= r_b) begin
	      s_res = 0;
	      r_res = r_a - r_b;
	   end
	   else begin
	      s_res = 1;
	      r_res = r_b - r_a;
	   end
	   if (f_a >= f_b)
	     f_res = f_a - f_b;
	   else
	     f_res = f_b - f_a;
	end // case: 2'b01
	2'b10: begin
	   fp_carry = 0;
	   if (r_a >= r_b) begin
	      s_res = 1;
	      r_res = r_a - r_b;
	   end
	   else begin
	      s_res = 0;
	      r_res = r_b - r_a;
	   end
	   if (f_a >= f_b)
	     f_res = f_a - f_b;
	   else
	     f_res = f_b - f_a;
	end // case: 2'b10
	2'b11: begin
	   f_res = f_a + f_b;
	   r_res = r_a + r_b;
	   s_res = 1;
	   if(f_a != 0 && f_b != 0 && f_res == 0)
	     fp_carry = 1;
	   else
	     fp_carry = 0;
	   r_res = fp_carry ? r_res+1 : r_res;
	end
      endcase // case ({neg_a, neg_b})
   end // always_comb

endmodule: fpu_add

//module tb_add
 // (input logic [31:0] result,
  // output logic [31:0] a, b)

  //fpu_add dut(.*);

 // initial begin
     
