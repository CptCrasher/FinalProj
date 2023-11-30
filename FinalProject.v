module FinalProject(KEY[1:0],SW0,SW9,cin,cin2,HEX0[7:0],HEX1[7:0],HEX2[7:0],HEX3[7:0],HEX4[7:0],HEX5[7:0],LEDR);

	input [1:0] KEY;
	input SW0, SW9, cin,cin2;
	output [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,LEDR;

	wire cout,lock;
	wire [31:0] dec;
	
	reg [31:0] p1_score,p2_score = 32'd0;
	reg p1_holder,p2_holder,p1_punish,p2_punish = 0;
	
	reg SW0_prev, SW9_prev;
	
	reg set_idle = 0;
	wire in_progress;
	ClockDivider(cin,cout);
	Counter(cout,~KEY[1],dec,lock,LEDR,set_idle,in_progress);

	
	reg [31:0] counter;
	reg SW0_debounced, SW9_debounced;

	always @(posedge cin) begin
    if (counter == 32'd0) begin
        if (SW0 != SW0_debounced) begin
            counter <= 32'd50000; // 50ms debounce time
            SW0_debounced <= SW0;
        end
        if (SW9 != SW9_debounced) begin
            counter <= 32'd50000; // 50ms debounce time
            SW9_debounced <= SW9;
        end
    end else begin
        counter <= counter - 32'd1;
    end
	end
	
	
	
	always @(posedge cin)
	begin
		if(lock == 1)
		begin
			if((SW0_debounced == 1) && (SW0_debounced && ~SW0_prev) && in_progress)
			begin
				p1_score <= p1_score + 32'd1;
				set_idle = 1;
			end else if((SW9_debounced == 1) && (SW9_debounced && ~SW9_prev) && in_progress)
			begin
				p2_score <= p2_score + 32'd1;
				set_idle = 1;
			end
			
	//If the countdown isn't finished		
		end else if(!lock) 
		begin
			if((SW0_debounced == 1) && (SW0_debounced && ~SW0_prev) && p1_score > 32'd0 && in_progress)
			begin
				p1_score <= p1_score - 32'd1;
				set_idle = 1;
			end else if((SW9_debounced == 1) && (SW9_debounced && ~SW9_prev) && p2_score > 32'd0 && in_progress)
			begin
				p2_score <= p2_score - 32'd1;
				set_idle = 1;
			end
		end
		
		set_idle = 0;
		if(~KEY[0])
		begin
			p1_score <= 32'd0;
			p2_score <= 32'd0;
		end
		
		SW0_prev <= SW0_debounced;
		SW9_prev <= SW9_debounced;
		
	end
//	segmentDisplay(p1_score, p2_score, HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	display(p1_score,HEX0);
	
endmodule



//Clock Divider for 1ms clock
module ClockDivider(cin,cout);
 input cin;
 output reg cout;
 reg[31:0] count;
 parameter D = 32'd2500000;//Every 1ms 
	 always @(posedge cin)
		 begin
		 count <= count + 32'd1;
			 if (count >= (D-1)) begin
				 cout <= ~cout;
				 count <= 32'd0;
			 end
	 end
endmodule

module Counter(clk,reset,dec,lock,LEDR,set_idle,in_progress);

	input clk, reset, set_idle;
	output reg[31:0] dec = 32'd0; 
	output reg lock, in_progress;
	output LEDR;
	
	reg light_on;
	
				
	always @(posedge clk)
	begin
		if(dec > 32'd1)
		begin
			dec <= dec - 32'd1;
			in_progress = 1;
		end else begin
			dec <= dec;
			in_progress = 1;
		end
	
		if(set_idle)begin
			dec <= 32'd0;
			in_progress = 0;
		end
		if(reset)begin
			dec <= 32'd50;
			in_progress = 1;
		end	
	end
	
	//Check to see if 'dec' counted down to 0, if set lock to 1 to allow players to score
	always @(dec)
	begin
		if(dec == 32'd1)
		begin
			lock = 1;
			light_on <= 1;
		end 
		else 
		begin
			lock = 0;
			light_on <= 0;
		end
	end

	assign LEDR = light_on;

endmodule

module display(p1,HEX0[7:0]);
	input [31:0] p1;
	output [7:0] HEX0;
	reg [7:0] f;
	always @(p1)
	begin
		case(p1)
				32'd0: begin
					f = 8'b11000000;
				end
				32'd1: begin
					f = 8'b11111001;
				end
				32'd2: begin
					f = 8'b10100100;
				end
				32'd3: begin
					f = 8'b10110000;
				end
				32'd4: begin
					f = 8'b10011001;
				end
				32'd5: begin
					f = 8'b10010010;
				end
				default: begin
					f = 8'b11111111;
				end
		endcase		
	end
	assign HEX0[0] = f[0];
	assign HEX0[1] = f[1];
	assign HEX0[2] = f[2];
	assign HEX0[3] = f[3];
	assign HEX0[4] = f[4];
	assign HEX0[5] = f[5];
	assign HEX0[6] = f[6];
	assign HEX0[7] = f[7];
endmodule


module segmentDisplay(p1, p2, HEX0[7:0],HEX1[7:0],HEX2[7:0],HEX3[7:0],HEX4[7:0],HEX5[7:0]);
	input [31:0] p1, p2;
	reg [7:0] a, b, c, d, e, f;
	output [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
	always @(p1,p2)
	begin
		if (p1 < 32'd5 && p2 < 32'd5) begin
			// display first player's score
			case(p1)
				32'd0: begin
					a = 7'b11000000;
				end
				32'd1: begin
					a = 7'b11111001;
				end
				32'd2: begin
					a = 7'b10100100;
				end
				32'd3: begin
					a = 7'b10110000;
				end
				32'd4: begin
					a = 7'b10011001;
				end
			endcase
			b = 7'b10111111; // display '-' for second character
			// display second player's score
			case(p2)
				32'd0: begin
					c = 7'b11000000;
				end
				32'd1: begin
					c = 7'b11111001;
				end
				32'd2: begin
					c = 7'b10100100;
				end
				32'd3: begin
					c = 7'b10110000;
				end
				32'd4: begin
					c = 7'b10011001;
				end
			endcase
			d = 7'b11111111;
			e = 7'b11111111;
			f = 7'b11111111;
		end else begin // one of the players has won
			a = 7'b10001100; // display "P"
			c = 7'b11000001; // display "V"
			d = 7'b11111001; // display "I"
			e = 7'b11000110; // display "C"
			f = 7'b10000111; // display "t"
			if (p1 == 32'd5) begin
				b = 7'b11111001; // display "1" for p1
			end else if (p2 == 32'd5) begin
				b = 7'b10100100; // display "2" for p2
			end
		end
	end
	assign HEX5[0] = a[0];
	assign HEX5[1] = a[1];
	assign HEX5[2] = a[2];
	assign HEX5[3] = a[3];
	assign HEX5[4] = a[4];
	assign HEX5[5] = a[5];
	assign HEX5[6] = a[6];
	assign HEX5[7] = a[7];
	
	assign HEX4[0] = b[0];
	assign HEX4[1] = b[1];
	assign HEX4[2] = b[2];
	assign HEX4[3] = b[3];
	assign HEX4[4] = b[4];
	assign HEX4[5] = b[5];
	assign HEX4[6] = b[6];
	assign HEX4[7] = b[7];
	
	assign HEX3[0] = c[0];
	assign HEX3[1] = c[1];
	assign HEX3[2] = c[2];
	assign HEX3[3] = c[3];
	assign HEX3[4] = c[4];
	assign HEX3[5] = c[5];
	assign HEX3[6] = c[6];
	assign HEX3[7] = c[7];

	assign HEX2[0] = d[0];
	assign HEX2[1] = d[1];
	assign HEX2[2] = d[2];
	assign HEX2[3] = d[3];
	assign HEX2[4] = d[4];
	assign HEX2[5] = d[5];
	assign HEX2[6] = d[6];
	assign HEX2[7] = d[7];

	assign HEX1[0] = e[0];
	assign HEX1[1] = e[1];
	assign HEX1[2] = e[2];
	assign HEX1[3] = e[3];
	assign HEX1[4] = e[4];
	assign HEX1[5] = e[5];
	assign HEX1[6] = e[6];
	assign HEX1[7] = e[7];

	assign HEX0[0] = f[0];
	assign HEX0[1] = f[1];
	assign HEX0[2] = f[2];
	assign HEX0[3] = f[3];
	assign HEX0[4] = f[4];
	assign HEX0[5] = f[5];
	assign HEX0[6] = f[6];
	assign HEX0[7] = 1;

endmodule
