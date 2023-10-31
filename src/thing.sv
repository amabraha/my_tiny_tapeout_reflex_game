`default_nettype none

//source: https://www.partow.net/programming/polynomials/index.html#deg08
module LFSR #(parameter mode = 0) 
    (input logic[7:0] seed, 
    input logic clock, reset, en, 
    output logic[7:0] out);
    generate
        always_ff @(posedge clock) begin
            if(reset)
                out <= seed;
            else if (en) begin
                out[7:1] <= out[6:0];
                if(mode == 0)
                    out[0] <= out[7] ^ out[3] ^ out[2] ^ out[1];
                else
                    out[0] <= out[7] ^ out[4] ^ out[2] ^ out[0];
            end
        end
    endgenerate

endmodule: LFSR


module top
    (input logic clock, reset,
    input logic [7:0] main_buttons,
    output logic [7:0] main_lights,
    input logic start,
    output logic correct_light, incorrect_light
    );

    logic [7:0] p1_out, code, presses;

    assign presses=main_buttons;

    LFSR #(0) lfsr1(.seed(8'b1), .clock, .reset, .en(1'b1), .out(p1_out));
    LFSR #(1) lfsr2(.seed(p1_out), .clock, .reset(start), .en(1'b1), .out(code));

    player p(.lights(main_lights), .reset(start), .*);

endmodule: top

module player
    (input logic[7:0] presses,
    output logic[7:0] lights,
    input logic clock, reset,
    input logic[7:0] code,
    output logic correct_light, incorrect_light);

    logic [7:0] debounce_states, button_states;

    logic reset_debounce;

    genvar i;
    generate
        for(i = 0; i < 8; i ++) begin
            always_ff @(posedge clock) begin
                if(reset_debounce) begin
                    debounce_states[i] <= 1'b0;
                    button_states[i] <= 1'b0;
                end else begin
                    debounce_states[i] <= presses[i];
                    if(presses[i] & (~debounce_states[i]))
                        button_states[i] <= ~button_states[i];
                end
            end
        end
    endgenerate

    logic[7:0] stored_code;

    enum logic[3:0] {RESET, START, CHECK} state;

    logic[31:0] timer;
    localparam T1 = 1;
    localparam T2 = 200; //T2-T1 is how long we play the game for
    localparam T3 = 210; //T3-T2 is how long we display the result signal
    localparam T4 = T3+1;

    always_ff @(posedge clock) begin
        if(reset) begin
            reset_debounce <= 1'b1;
            timer <= 32'b0;
            correct_light <= 1'b0;
            incorrect_light <= 1'b0;
            state <= RESET;
        end else begin
            timer <= timer+32'b1;
            correct_light <= 1'b0;
            incorrect_light <= 1'b0;
            if (timer < T1) begin
                state <= RESET;
            end else if (timer < T2) begin
                state <= START;
                stored_code <= (state == RESET) ? code : stored_code;
                reset_debounce <= (state == RESET) ? 1'b1 : 1'b0;
                lights <= stored_code ^ button_states;
            end else if (timer < T3) begin
                state <= CHECK;
                correct_light <= (state == START) ? (lights == 0) : correct_light;
                incorrect_light <= (state == START) ? (lights != 0) : incorrect_light;
                incorrect_light <= (lights != 0) ? 1'b1 : stored_code;
                reset_debounce <= (state == RESET) ? 1'b1 : 1'b0;
                lights <= stored_code ^ button_states;
            end else if (timer < T4) begin
                state <= RESET;
                timer <= 32'b0;
            end
        end
    end



endmodule: player

module TB();
    logic clock, reset;
    logic [7:0] buttons;
    logic start;
    logic [7:0] lights;
    logic correct, incorrect;
    top DUT(.main_buttons(buttons), .main_lights(lights), .correct_light(correct), .incorrect_light(incorrect), .*);


    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end
    
    initial begin
        reset = 1'b1;
        buttons = 8'b0000_0000;
        @(posedge clock);
        reset <= 1'b0;
        #200;
        @(posedge clock);
        start <= 1'b1;
        @(posedge clock);
        start <= 1'b0;
        wait(DUT.p.state == DUT.p.START);
        @(posedge clock);

        buttons[0] <= 1'b1;
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        buttons[0] <= 1'b0;

        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        buttons[0] <= 1'b1;
        buttons[1] <= 1'b1;
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        buttons[0] <= 1'b0;
        buttons[1] <= 1'b0;
        
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        buttons[2] <= 1'b1;
        buttons[3] <= 1'b1;
        buttons[4] <= 1'b1;
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        buttons[2] <= 1'b0;
        buttons[3] <= 1'b0;
        buttons[4] <= 1'b0;

        wait(DUT.p.state == DUT.p.RESET);
        wait(DUT.p.state == DUT.p.START);
        @(posedge clock);
        
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        buttons[0] <= 1'b1;
        buttons[1] <= 1'b1;
        buttons[3] <= 1'b1;
        buttons[7] <= 1'b1;
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        buttons[0] <= 1'b0;
        buttons[1] <= 1'b0;
        buttons[3] <= 1'b0;
        buttons[7] <= 1'b0;

        #5000 $finish;
    end
endmodule: TB

module tt_um_reflex_game
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

    top DUT(.main_buttons(ui_in[7:0]), .main_lights(uo_out[7:0]), .correct_light(uio_out[1]), .incorrect_light(uio_out[2]), .start(uio_in[0]), .clock(clk), .reset(~rst_n));
    assign uio_oe = 8'b0000_0110;

endmodule: tt_um_reflex_game
