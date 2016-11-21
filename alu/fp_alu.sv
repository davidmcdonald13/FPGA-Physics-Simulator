`default_nettype none 

`define ADD 2'b00
`define SUB 2'b01
`define MUL 2'b10
`define DIV 2'b11

module fp_alu
  #(parameter n = 32)
   (input logic [n-1:0] a, b,
    input logic [1:0] op,
    output logic [n-1:0] result);

   logic [(2*n)-1:0] 	 buf_result, buf_a, buf_b, big_buf;
   logic [n-1:0] pos_a, pos_b;
   logic 		 s ;
   

   assign s = a[n-1]^b[n-1];
   
   always_comb begin
      buf_result = 0;
      result = 0;
      buf_a = 0;
      buf_b = 0;
      pos_a = 'd0;
      pos_b = 'd0;
      case(op)
	`ADD: result = a + b;
	`SUB: result = a + (~b+1);
	`MUL: begin
        pos_a = a[n-1] ? ~a + 1 : a;
        pos_b = b[n-1] ? ~b + 1 : b;
	   big_buf = pos_a * pos_b;//{s,a[n-2:0]*b[n-2:0]};
	   buf_result = big_buf >> (n/2);
       if (s)
           result = 1 + ~buf_result[n-1:0];
        else
            result = buf_result[n-1:0];
	end
	`DIV: begin
	   buf_a = {{(n+1){1'b0}},a[n-2:0]};
	   buf_b = {{(n+1){1'b0}},b[n-2:0]};
	   buf_a = buf_a << (n/2);
	   buf_result = buf_a/buf_b;
	   result = buf_result[n-2:0];
	   result[n-1] = s;
	end
      endcase // case (op)
   end // always_comb

endmodule: fp_alu
/*
module tb
  (output logic [31:0] a, b,
   output logic [1:0]  op);

   logic [31:0]        result;
   
   fp_alu dut(a, b, op, result);
   
   initial begin
      a = 'd3;
      b = 'd2;
      op = `MUL;
      
     #10  $display("result=%d",result);
   end

endmodule: tb
*/
