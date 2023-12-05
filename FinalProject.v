module FinalProject(KEY[1:0],SW0,SW9,cin,HEX0[7:0],HEX1[7:0],HEX2[7:0],HEX3[7:0],HEX4[7:0],HEX5[7:0],LEDR,ARDUINO[3:0]);
	//For Arduino [0] = Buzzer, [1] = Red LED, [2] = Green LED
	
	//Declaring inputs, outputs, wires, regs and staging modules
	input [1:0] KEY;
	input SW0, SW9, cin;
	output [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,LEDR;
	output [3:0] ARDUINO;
	
	wire cout,decimal_toggle,lock,in_progress,SW0_debounced,SW9_debounced,winner;
	wire [31:0] dec;
	reg [31:0] p1_score,p2_score = 32'd0;
	reg SW0_prev,SW9_prev,set_idle = 0;
	reg p1_change,p2_change = 0;
	
	ClockDivider(cin,cout,decimal_toggle);
	Counter(cout,~KEY[1],dec,lock,LEDR,set_idle,in_progress,ARDUINO[3:0],winner,decimal_toggle);
	Debouncer(cin,SW0,SW9,SW0_debounced,SW9_debounced);
	segmentDisplay(p1_score, p2_score, HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,decimal_toggle,p1_change,p2_change,winner);
	
	
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
				p1_change = 1;
				p2_change = 0;
			end else if((SW9_debounced) && (SW9_debounced && ~SW9_prev) && in_progress)
			begin
				p2_score <= p2_score + 32'd1;
				set_idle = 1;
				p2_change = 1;
				p1_change = 0;
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
				p1_change = 1;
				p2_change = 0;
			end else if((SW9_debounced) && (SW9_debounced && ~SW9_prev) && p2_score > 32'd0 && in_progress)
			begin
				p2_score <= p2_score - 32'd1;
				set_idle = 1;
				p2_change = 1;
				p1_change = 0;
			//If a players switch is left in the 'on' state and the game isn't in progress, insantly set back to the idle state (stops round from starting)	
			end else if(SW0_debounced||SW9_debounced)
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
			p2_change = 0;
			p1_change = 0;
		end
		
		//Used to communicate to 'Counter' - When counter has set game to idle state, turn the 'set_idle' variable back to 0
		if(!in_progress)
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
	//Only capture the states of SW0 and SW9 every 10 ms
	always @(posedge cin) begin
		if (counter == 32'd0) begin
			if (SW0 != SW0_debounced) begin //Player 1
				counter <= 32'd500000; //Every 10ms updated switch state
				SW0_debounced <= SW0;
			end
			if (SW9 != SW9_debounced) begin //Player 2
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
module ClockDivider(cin,cout,decimal_toggle);
 input cin;
 output reg cout,decimal_toggle;
 reg[31:0] count,decimal_count;
 parameter D = 32'd2500000; //50k for 1 ms 25k
 parameter D_decimal = 32'd12500000; // Every 0.5 ms
	 always @(posedge cin)
		 begin
		 decimal_count <= decimal_count + 32'd1;
		 count <= count + 32'd1;
			 if (count >= (D-1)) begin
				 cout <= ~cout;
				 count <= 32'd0;
			 end
			 if (decimal_count >= (D_decimal-1)) begin
				 decimal_toggle <= ~decimal_toggle;
				 decimal_count <= 32'd0;
			 end
	 end
endmodule


//Module used to handle the game countdown, set states for the game (whether countdown/lock is active or not) and toggle Arduino outputs 
module Counter(clk,reset,dec,lock,LEDR,set_idle,in_progress,ARDUINO[3:0],winner,decimal_toggle);

	input clk, reset, set_idle,winner,decimal_toggle;
	output [3:0] ARDUINO;
	output reg[31:0] dec = 32'd0; 
	output reg lock, in_progress;
	output LEDR;
	reg score_state,yellow_LED,red_LED,green_LED = 0;
	reg [31:0] count,countdown;
	reg [4:0] lights = 5'b10000;
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
			red_LED = 0;
			yellow_LED = 0;
			green_LED = 0;
		end
		
		count <= count + 32'd1;
		if (count >= 32'd100) begin
			count <= 32'd0;
		end
		//When button is pressed, countdown starts by setting 'dec' to a random value to countdown from. Also set 'in_progress' to 1 telling us we are not in idle state
		if(reset)begin
			countdown <= count + 32'd50;
			dec <= countdown;
			in_progress = 1;
			red_LED = 1;
			yellow_LED = 0;
			green_LED = 0;
		end

		//Toggle the Arduino LEDs based on the countdown	
		if(dec < (countdown >> 1) && dec > 32'd0 && !winner && in_progress)
			yellow_LED = 1;
			
		if(dec == 32'd0)
			yellow_LED = 0;
			
		if(score_state && !winner)begin
			red_LED = 0;
			yellow_LED = 0;
			green_LED = 1;
		end else begin
			green_LED = 0;
		end		

		// Flash all the LEDs for the victory screen
		if(winner) begin
			lights = lights >>> 1;
			case(lights)
			5'b00100: begin
				green_LED = 1;
				yellow_LED = 0;
				red_LED = 0;
			end
			5'b00010: begin
				green_LED = 0;			
				yellow_LED = 1;
				red_LED = 0;				
			end
			5'b00001: begin
				green_LED = 0;			
				yellow_LED = 0;
				red_LED = 1;
			end
			5'b00000: begin
				lights = 5'b10000;
			end				
			default: begin
				green_LED = 0;			
				yellow_LED = 0;
				red_LED = 0;
			end
		   endcase
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

	//Assign outputs to turn on/off LEDs/Buzzer
	assign LEDR = score_state;
	assign ARDUINO[0] = score_state; //Buzzer
	assign ARDUINO[1] = red_LED; //Red LED
	assign ARDUINO[2] = yellow_LED; //Yellow LED
	assign ARDUINO[3] = green_LED; //Green LED
endmodule


//Module used to handle displaying score + win message on 7 segment displays
module segmentDisplay(p2, p1, HEX0[7:0],HEX1[7:0],HEX2[7:0],HEX3[7:0],HEX4[7:0],HEX5[7:0],clk,p1_change,p2_change,winner);
	input [31:0] p1, p2;
	input p1_change,p2_change,clk;
	output [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
	output reg winner = 0;
	reg [7:0] b, c, d, e;
	reg [6:0] a, f;
	reg decimal_a, decimal_f = 1;
	
	always @(p1,p2)
	begin
		if (p1 >= 32'd5 || p2 >= 32'd5) //One of the players has won
		begin
			winner = 1;
			a = 7'b0001100; //Display "P"
			c = 8'b11000001; //Display "V"
			d = 8'b11111001; //Display "I"
			e = 8'b11000110; //Display "C"
			f = 7'b0000111; //Display "t"
			if (p1 == 32'd5) begin
				b = 8'b11111001; //Display "1" for p1
			end else if (p2 == 32'd5) begin
				b = 8'b10100100; //Display "2" for p2
			end
		end else begin //No winner yet, display the score
			//Display first player's score
			case(p1)
				32'd0: begin //p1 score = 0
					a = 7'b1000000;
				end
				32'd1: begin //p1 score = 1
					a = 7'b1111001;
				end
				32'd2: begin //p1 score = 2
					a = 7'b0100100;
				end
				32'd3: begin //p1 score = 3
					a = 7'b0110000;
				end
				32'd4: begin //p1 score = 4
					a = 7'b0011001;
				end
			endcase
			//Display second player's score
			case(p2)
				32'd0: begin //p2 score = 0
					f = 7'b1000000;
				end
				32'd1: begin //p2 score = 1
					f = 7'b1111001;
				end
				32'd2: begin //p2 score = 2
					f = 7'b0100100;
				end
				32'd3: begin //p2 score = 3
					f = 7'b0110000;
				end
				32'd4: begin //p2 score = 4
					f = 7'b0011001;
				end
			endcase
			//Display '-' for characters 2-5 to separate each player's score
			b = 8'b10111111;
			c = 8'b10111111;
			d = 8'b10111111;
			e = 8'b10111111;
			winner = 0;
		end
	end
	
	//Used to toggle the decimal for p1 or p2 depending on if their score changed
	always @(posedge clk)
	begin
		if(p1_change && !winner)
		begin
			decimal_f = ~decimal_f;
			decimal_a = 1;
		end else if(p2_change && !winner)
		begin
			decimal_a = ~decimal_a;
			decimal_f = 1;
		end else begin
			decimal_a = 1;
			decimal_f = 1;
		end
	end
	
	//Segment display for HEX5
	assign HEX5[0] = a[0];
	assign HEX5[1] = a[1];
	assign HEX5[2] = a[2];
	assign HEX5[3] = a[3];
	assign HEX5[4] = a[4];
	assign HEX5[5] = a[5];
	assign HEX5[6] = a[6];
	assign HEX5[7] = decimal_a; //Turns on or off depending on if p1 got or lost a point
	
	//Segment display for HEX4
	assign HEX4[0] = b[0];
	assign HEX4[1] = b[1];
	assign HEX4[2] = b[2];
	assign HEX4[3] = b[3];
	assign HEX4[4] = b[4];
	assign HEX4[5] = b[5];
	assign HEX4[6] = b[6];
	assign HEX4[7] = b[7];
	
	//Segment display for HEX3
	assign HEX3[0] = c[0];
	assign HEX3[1] = c[1];
	assign HEX3[2] = c[2];
	assign HEX3[3] = c[3];
	assign HEX3[4] = c[4];
	assign HEX3[5] = c[5];
	assign HEX3[6] = c[6];
	assign HEX3[7] = c[7];

	//Segment display for HEX2
	assign HEX2[0] = d[0];
	assign HEX2[1] = d[1];
	assign HEX2[2] = d[2];
	assign HEX2[3] = d[3];
	assign HEX2[4] = d[4];
	assign HEX2[5] = d[5];
	assign HEX2[6] = d[6];
	assign HEX2[7] = d[7];

	//Segment display for HEX1
	assign HEX1[0] = e[0];
	assign HEX1[1] = e[1];
	assign HEX1[2] = e[2];
	assign HEX1[3] = e[3];
	assign HEX1[4] = e[4];
	assign HEX1[5] = e[5];
	assign HEX1[6] = e[6];
	assign HEX1[7] = e[7];

	//Segment display for HEX0
	assign HEX0[0] = f[0];
	assign HEX0[1] = f[1];
	assign HEX0[2] = f[2];
	assign HEX0[3] = f[3];
	assign HEX0[4] = f[4];
	assign HEX0[5] = f[5];
	assign HEX0[6] = f[6];
	assign HEX0[7] = decimal_f; //Turns on or off depending on if P2 got or lost a point

endmodule