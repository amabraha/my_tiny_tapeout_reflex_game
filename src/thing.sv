// Code your design here


module tt_um_calculator_chip
  (input logic clock, Enter, Reset,
   input logic [7:0] NumIn,
   input logic [1:0] OpIn,
   output logic [7:0] NumOut
  );
  
  enum logic {ME, NOTME}button;
  
  always_ff @(posedge clock, posedge Reset) begin
    if (Reset)
      NumOut <= 8'b0;
    else begin
      if(Enter)
        button <= ME;
      else
        button <= NOTME;
      if((button == NOTME) & Enter) begin
        case(OpIn)
          2'd0: NumOut <= NumOut + NumIn;
          2'd1: NumOut <= NumOut - NumIn;
          2'd2: NumOut <= NumOut | NumIn;
          2'd3: NumOut <= (NumOut == NumIn) ? 8'b1 : 8'b0;
        endcase
      end
    end
  end
  
endmodule: calculator_chip
