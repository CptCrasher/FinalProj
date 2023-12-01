module FinalProject(KEY[1:0],SW0,SW9,cin,cin2,HEX0[7:0],HEX1[7:0],HEX2[7:0],HEX3[7:0],HEX4[7:0],HEX5[7:0],LEDR,ARDUINO[2:0]);
	//For Arduino [0] = Buzzer, [1] = Red LED, [2] = Green LED
	
	//Declaring inputs, outputs, wires, regs and staging modules
	input [1:0] KEY;
	input SW0, SW9, cin,cin2;
	output [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,LEDR;
	output [2:0] ARDUINO;
	
	wire cout,lock,in_idle,in_progress,SW0_debounced,SW9_debounced;
	wire [31:0] dec;
	reg [31:0] p1_score,p2_score = 32'd0;
	reg SW0_prev,SW9_prev,set_idle = 0;
	
	ClockDivider(cin,cout);
	Counter(cout,~KEY[1],dec,lock,LEDR,set_idle,in_progress,in_idle,ARDUINO[2:0]);
	Debouncer(cin,SW0,SW9,SW0_debounced,SW9_debounced);
	segmentDisplay(p1_score, p2_score, HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	
	
	always @(posedge cin)
	begin
	//If the countdown is finished (lock = 1)
		if(lock)
		begin
		//If a player flips their switch after the countdown is done, remove a point to the associated player and set the state back to idle (Only count the initial flipping of the switch)
			if((SW0_debounced) && (SW0_debounced && ~SW0_prev) && in_progress)
			begin
				p1_score <= p1_score + 32'd1;
				set_idle = 1;
			end else if((SW9_debounced) && (SW9_debounced && ~SW9_prev) && in_progress)
			begin
				p2_score <= p2_score + 32'd1;
				set_idle = 1;
			end
			
	//If the countdown isn't finished (lock = 0)		
		end else if(!lock) 
		begin
			//If a player flips their switch before the countdown is done, remove a point to the associated player a point and set the state back to idle (Only count the initial flipping of the switch)
			//Only remove a point if the associated player has a score greater than 0
			if((SW0_debounced) && (SW0_debounced && ~SW0_prev) && p1_score > 32'd0 && in_progress)
			begin
				p1_score <= p1_score - 32'd1;
				set_idle = 1;
			end else if((SW9_debounced) && (SW9_debounced && ~SW9_prev) && p2_score > 32'd0 && in_progress)
			begin
				p2_score <= p2_score - 32'd1;
				set_idle = 1;
			//If a players switch is left in the 'on' state and the game isn't in progress, insantly set back to the idle state (stops round from starting)	
			end else if(SW0_debounced|| SW9_debounced)
			begin
				set_idle = 1;
			end
		end
		
		//Reset the scores to 0 and set back to idle state
		if(~KEY[0])
		begin
			p1_score <= 32'd0;
			p2_score <= 32'd0;
			set_idle = 1;
		end
		
		//Used to communicate to 'Counter' - When counter has set game to idle state, turn the 'set_idle' variable back to 0
		if(in_idle)
			set_idle = 0;
			
		//Used to obtain previous values of switches to only capture initial flipping of SW0 and SW9
		SW0_prev <= SW0_debounced;
		SW9_prev <= SW9_debounced;
	end
endmodule

//Debouncer used to fix inconsistencies with mechanical flip switch
module Debouncer(cin,SW0,SW9,SW0_debounced,SW9_debounced);
	input cin,SW0,SW9;
	output reg SW0_debounced,SW9_debounced;
	reg [31:0] counter;
	//Only capture the states of SW0 and SW9 every 
	always @(posedge cin) begin
    if (counter == 32'd0) begin
        if (SW0 != SW0_debounced) begin
            counter <= 32'd500000; //Every 10ms updated switch state
            SW0_debounced <= SW0;
        end
        if (SW9 != SW9_debounced) begin
            counter <= 32'd500000; //Every 10ms updated switch state
            SW9_debounced <= SW9;
        end
    end else begin
        counter <= counter - 32'd1;
    end
	end
	
endmodule

//Clock Divider for 1ms clock
//Time = # of cycles / frequency -> 25,000 / 50,000,000 = 0.0005s
//Every 0.0005s cout changes state -> 0.0005 x 2 = 0.001s or 1ms
module ClockDivider(cin,cout);
 input cin;
 output reg cout;
 reg[31:0] count;
 parameter D = 32'd25000; 
	 always @(posedge cin)
		 begin
		 count <= count + 32'd1;
			 if (count >= (D-1)) begin
				 cout <= ~cout;
				 count <= 32'd0;
			 end
	 end
endmodule

//Module used to handle the game countdown, set states for the game (whether countdown/lock is active or not) and toggle Arduino outputs 
module Counter(clk,reset,dec,lock,LEDR,set_idle,in_progress,in_idle,ARDUINO[2:0]);

	input clk, reset, set_idle;
	output [2:0] ARDUINO;
	output reg[31:0] dec = 32'd0; 
	output reg lock, in_progress,in_idle;
	output LEDR;
	
	reg score_state = 0;
	
	//Decrease 1 for 'dec' until 'dec' is 1. 1 is used for the end of the countdown, 0 is used as the 'idle' state			
	always @(posedge clk)
	begin
	
		if(dec > 32'd1)
		begin
			dec <= dec - 32'd1;	
		end else begin
			dec <= dec;
		end
	
	   //If our top module tells us to go into idle state, set 'dec' to 0 (0 is idle state). Also set 'in_progress' to 0 telling us we are in idle state
		if(set_idle)begin
			dec <= 32'd0;
			in_progress = 0;
			in_idle = 1;
		end
		
		//When button is pressed, countdown starts by setting 'dec' to a random value to countdown from. Also set 'in_progress' to 1 telling us we are not in idle state
		if(reset)begin
			dec <= 32'd50;
			in_progress = 1;
			in_idle = 0;
		end	
	end
	
	//Keep checking the value of dec everytime it updates
	always @(dec)
	begin
		//If 'dec' is 1 countdown is done and set lock to 1. Also turn on score state which is used to toggle Arduino outputs
		if(dec == 32'd1)
		begin
			lock = 1;
			score_state <= 1;
		//If 'dec' is not one, countdown is not done or we are in idle state ('dec' = 0). Set lock to 0 and turn off score state which is used to toggle Arduino outputs	
		end else begin
			lock = 0;
			score_state <= 0;
		end
	end

	//Assign outputs to turn on/off LEDS/Buzzer
	assign LEDR = score_state;
	assign ARDUINO[0] = score_state;
	assign ARDUINO[2] = score_state;
	assign ARDUINO[1] = in_progress;
endmodule

module segmentDisplay(p2, p1, HEX0[7:0],HEX1[7:0],HEX2[7:0],HEX3[7:0],HEX4[7:0],HEX5[7:0]);
	input [31:0] p1, p2;
	reg [7:0] a, b, c, d, e, f;
	output [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
	
	always @(p1,p2)
	begin
		if (p1 >= 32'd5 or p2 >= 32'd5) begin // one of the players has won
			winner = 1;
			a = 8'b10001100; // display "P"
			c = 8'b11000001; // display "V"
			d = 8'b11111001; // display "I"
			e = 8'b11000110; // display "C"
			f = 8'b10000111; // display "t"
			if (p1 == 32'd5) begin
				b = 8'b11111001; // display "1" for p1
			end else if (p2 == 32'd5) begin
				b = 8'b10100100; // display "2" for p2
			end
		end else begin // no winner yet, display the score
			// display first player's score
			case(p1)
				32'd0: begin
					a = 7'b1000000;
				end
				32'd1: begin
					a = 7'b1111001;
				end
				32'd2: begin
					a = 7'b0100100;
				end
				32'd3: begin
					a = 7'b0110000;
				end
				32'd4: begin
					a = 7'b0011001;
				end
			endcase
			// display second player's score
			case(p2)
				32'd0: begin
					f = 7'b1000000;
				end
				32'd1: begin
					f = 7'b1111001;
				end
				32'd2: begin
					f = 7'b0100100;
				end
				32'd3: begin
					f = 7'b0110000;
				end
				32'd4: begin
					f = 7'b0011001;
				end
			endcase
			// display '-' for characters 2-5 to separate the scores
			b = 8'b10111111;
			c = 8'b10111111;
			d = 8'b10111111;
			e = 8'b10111111;
			winner = 0;
		end
	end
	
	// used to toggle the decimal for p1 or p2 depending on if their score changed
	always @(posedge clk)
	begin
		if(p1_change)
		begin
			decimal_f = ~decimal_f;
			decimal_a = 1;
		end else if(p2_change)
		begin
			decimal_a = ~decimal_a;
			decimal_f = 1;
		end else begin
			decimal_a = 1;
			decimal_f = 1;
		end
	end
	
	// segment display for HEX5
	assign HEX5[0] = a[0];
	assign HEX5[1] = a[1];
	assign HEX5[2] = a[2];
	assign HEX5[3] = a[3];
	assign HEX5[4] = a[4];
	assign HEX5[5] = a[5];
	assign HEX5[6] = a[6];
	assign HEX5[7] = decimal_a; // turns on or off depending on if p1 got or lost a point
	
	// segment display for HEX4
	assign HEX4[0] = b[0];
	assign HEX4[1] = b[1];
	assign HEX4[2] = b[2];
	assign HEX4[3] = b[3];
	assign HEX4[4] = b[4];
	assign HEX4[5] = b[5];
	assign HEX4[6] = b[6];
	assign HEX4[7] = b[7];
	
	// segment display for HEX3
	assign HEX3[0] = c[0];
	assign HEX3[1] = c[1];
	assign HEX3[2] = c[2];
	assign HEX3[3] = c[3];
	assign HEX3[4] = c[4];
	assign HEX3[5] = c[5];
	assign HEX3[6] = c[6];
	assign HEX3[7] = c[7];

	// segment display for HEX2
	assign HEX2[0] = d[0];
	assign HEX2[1] = d[1];
	assign HEX2[2] = d[2];
	assign HEX2[3] = d[3];
	assign HEX2[4] = d[4];
	assign HEX2[5] = d[5];
	assign HEX2[6] = d[6];
	assign HEX2[7] = d[7];

	// segment display for HEX1
	assign HEX1[0] = e[0];
	assign HEX1[1] = e[1];
	assign HEX1[2] = e[2];
	assign HEX1[3] = e[3];
	assign HEX1[4] = e[4];
	assign HEX1[5] = e[5];
	assign HEX1[6] = e[6];
	assign HEX1[7] = e[7];

	// segment display for HEX0
	assign HEX0[0] = f[0];
	assign HEX0[1] = f[1];
	assign HEX0[2] = f[2];
	assign HEX0[3] = f[3];
	assign HEX0[4] = f[4];
	assign HEX0[5] = f[5];
	assign HEX0[6] = f[6];
	assign HEX0[7] = decimal_f; // turns on or off depending on if p2 got or lost a point

endmodule