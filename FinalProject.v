FinalProject(Buttons[1:0],SW0,SW9,HEX0,HEX5,cin);

reg cout, lock;
reg[31:0] dec;

wire[31:0] p1_score,p2_score = 0;
wire p1_holder,p2_holder,p1_punish,p2_punish = 0;
ClockDivider(cin, cout);
counter(cout,~Buttons[1],dec, lock);


always @(SW0 or SW9)
begin
	//If the countdown finished (lock = 1)
	if(lock)
	begin
		if(SW0)
		begin
			p1_holder = 1;
			
		end else if(SW9)
		begin
			p2_holder = 1;
			
		end
	//If the countdown isn't finished (lock = 0) and a switch is flipped, set punish wire to 1	
	end else if(~lock) 
	begin
	   if(SW0 & p1_score > 0)
		begin
			p1_punish = 1;
			
		end else if(SW9 & p2_score > 0)
		begin
			p2_punish = 1;
			
		end
	end
		
end





endmodule



//When button 0 is pressed, game starts -> timer goes down subtracting a value every 1ms until value equals 0. when value is 0 then playesr can flip switch


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


module counter(clk, reset, dec, lock);

	input clk,reset;
	output reg[31:0] dec = 32'd0;
	output reg lock = 0;
	always @(posedge clk or posedge reset)
	begin
		if (reset == 1)
			dec <= 32'd50 //assign to a random number, this the amout of time before the players flip the switch
		
		//Subtract one from the decrementor 
		if (dec > 0)
			dec = dec - 1;
		
		//Once the countdown ends, set lock to 1 allowing players to press their switch. If the countdown isn't ended set lock to 0.
		if(dec == 32'd0)
		begin
			lock <= 1;
		end else begin
			lock <= 0;
		end
		
	end

endmodule

module segmentDisplay(p1, p2);
	input [31:0] p1, p2;
	reg [7:0] a, b, c, d, e, f;

	if (p1 < 32'd5 || p2 < 32'd5) begin
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
		b = 7'b11111101; // display '-' for second character
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
		a = 7'b10001100 // display "P"
		c = 7'b11000001 // display "V"
		d = 7'b11111001 // display "I"
		e = 7'b11000110 // display "C"
		f = 7'b10000111 // display "t"
		if (p1 == 32'd5) begin
			b = 7'b11111001; // display "1" for p1
		end else if (p2 == 32'd5) begin
			b = 7'b10100100; // display "2" for p2
		end
	end

	assign HEX5[0] = a[0];
	assign HEX5[1] = a[1];
	assign HEX5[2] = a[2];
	assign HEX5[3] = a[3];
	assign HEX5[4] = a[4];
	assign HEX5[5] = a[5];
	assign HEX5[6] = 1

	assign HEX4[0] = b[0];
	assign HEX4[1] = b[1];
	assign HEX4[2] = b[2];
	assign HEX4[3] = b[3];
	assign HEX4[4] = b[4];
	assign HEX4[5] = b[5];
	assign HEX4[6] = 1

	assign HEX3[0] = c[0];
	assign HEX3[1] = c[1];
	assign HEX3[2] = c[2];
	assign HEX3[3] = c[3];
	assign HEX3[4] = c[4];
	assign HEX3[5] = c[5];
	assign HEX3[6] = 1

	assign HEX2[0] = d[0];
	assign HEX2[1] = d[1];
	assign HEX2[2] = d[2];
	assign HEX2[3] = d[3];
	assign HEX2[4] = d[4];
	assign HEX2[5] = d[5];
	assign HEX2[6] = 1

	assign HEX1[0] = e[0];
	assign HEX1[1] = e[1];
	assign HEX1[2] = e[2];
	assign HEX1[3] = e[3];
	assign HEX1[4] = e[4];
	assign HEX1[5] = e[5];
	assign HEX1[6] = 1

	assign HEX0[0] = f[0];
	assign HEX0[1] = f[1];
	assign HEX0[2] = f[2];
	assign HEX0[3] = f[3];
	assign HEX0[4] = f[4];
	assign HEX0[5] = f[5];
	assign HEX0[6] = 1

endmodule