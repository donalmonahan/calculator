//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Donal C. Monahan
// Target Device: XC7A100T-csg324 on Digilent Nexys 4 board
// Description:   Calculator module to perform addition and multiplication.
//                Takes input from a module that deals with a number keypad.
//                Sends output to a digital display interface module.
//                Designed for a 5 MHz clock and synchronous reset.
//                
// Created: 30 November 2023
//  
//////////////////////////////////////////////////////////////////////////////////

module calculator(
	input newkey,
	input [4:0] keycode,
	input clk,
	input rst,
	output reg [19:0] x,
	output reg led							// overflow warning LED
	);
	
	localparam PLUS = 1'd0;					// 2-bit representation of PLUS operator
	localparam TIMES = 1'd1;				// 2-bit representation of TIMES operator
	localparam CLEAR20 = 20'd0;				// 20-bit 0 signal
	localparam CLEAR2 = 2'd0;				// 2-bit 0 signal
	localparam CLEAR1 = 1'd0;				// 1-bit 0 signal
	reg [19:0] y;
	reg op;
	reg [19:0] nextX;
	reg [19:0] nextY;
	reg nextOp;
	reg nextLED;
	reg [2:0] select;
	wire [19:0] sum;
	wire [19:0] product;
	wire [19:0] result;
	wire [19:0] ovp;						// product overflow
	wire ovs;								// sum overflow
	
	// Registers
	always @ (posedge clk)
		begin
			if (rst)
				begin
					x <= CLEAR20;
					y <= CLEAR20;
					op <= CLEAR1;
					led <= CLEAR1;
				end
			else
				begin
					x <= nextX;
					y <= nextY;
					op <= nextOp;
					led <= nextLED;
				end
		end
	
	// Multiplexers
  always @ (select, x, y, op, led, result, ovp, ovs, keycode)
		case(select)
			3'd0:						// if no button has been pressed
				begin
              		nextX = x;
					nextY = y;
					nextOp = op;
					nextLED = led;
				end
			
			3'd1:						// if + has been pressed
				begin
              		nextX = CLEAR20;
					nextY = x;
					nextOp = PLUS;
					nextLED = CLEAR1;
				end
			
			3'd2:						// if × has been pressed
				begin
              		nextX = CLEAR20;
					nextY = x;
					nextOp = TIMES;
					nextLED = CLEAR1;
				end
			
			3'd3:						// if = has been pressed
				begin
              		nextX = result;
					nextY = y;
					nextOp = op;
					nextLED = op ? (ovp != 0) : ovs;
				end	
			
			3'd4:						// if CA has been pressed
				begin
              		nextX = CLEAR20;
					nextY = CLEAR20;
					nextOp = CLEAR1;				// default operator is +; CLEAR1 = PLUS
					nextLED = CLEAR1;
				end
			
			3'd7:						// if number key has been pressed
				begin
              		nextX = {x[15:0],keycode[3:0]};	// shift x 4 bits left, concatenate value of input number to right
					nextY = y;
					nextOp = op;
					nextLED = CLEAR1;
				end
			
			default:					// invalid select values, carry on as if no button pressed	
				begin
              		nextX = x;
					nextY = y;
					nextOp = op;
					nextLED = led;
				end
		endcase
	
	// Lookup table for 'select'
	always @ (newkey, keycode)
		begin
			if(!newkey)	select <= 3'd0;				// no key pressed; select = 000
			else if(keycode[4]) select <= 3'd7;		// number key pressed; select = 111
			else select <= keycode[2:0];			// non-number key pressed; select = keycode[2:0]
		end
		
	// Logic for 'result'
	assign result = op ? product : sum;				// result = product if op = TIMES; result = SUM if op = PLUS (or op = CLEAR1)
	
	// Arithmetic
	assign {ovp, product} = x * y;					// overflow detected when ovp != 0
	assign {ovs, sum} = x + y;						// overflow detected when ovs = 1
	
endmodule	