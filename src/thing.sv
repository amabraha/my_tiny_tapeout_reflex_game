// Code your design here


module tt_um_calculator_chip
  (
   input  logic [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output logic [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  logic [7:0] uio_in,   // IOs: Bidirectional Input path
    output logic [7:0] uio_out,  // IOs: Bidirectional Output path
    output logic [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  logic       ena,      // will go high when the design is enabled
    input  logic       clk,      // clock
    input  logic       rst_n     // reset_n - low to reset
  );
  logic clock, Reset;
  logic [1:0] OpIn;
  logic [7:0] NumIn, NumOut;
  logic Enter;
  assign clock = clk;
  assign Reset = rst_n;
  assign OpIn=uio_in[1:0];
  assign uo_out = NumOut;
  assign NumIn = ui_in;
  assign Enter = uio_in[2];
  assign uio_oe = 8'b0;
  
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
  
endmodule: tt_um_calculator_chip
