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

// Test if branch works