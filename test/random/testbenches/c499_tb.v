module c499_tb();
parameter INPUT_WIDTH = 41;
parameter OUTPUT_WIDTH = 32;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c499.txt";
string OUTPUT_FILE = "output_vectors/c499.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c499 UUT (.N1(in[0]), .N5(in[1]), .N9(in[2]), .N13(in[3]), 
.N17(in[4]), .N21(in[5]), .N25(in[6]), .N29(in[7]), 
.N33(in[8]), .N37(in[9]), .N41(in[10]), .N45(in[11]), 
.N49(in[12]), .N53(in[13]), .N57(in[14]), .N61(in[15]), 
.N65(in[16]), .N69(in[17]), .N73(in[18]), .N77(in[19]), 
.N81(in[20]), .N85(in[21]), .N89(in[22]), .N93(in[23]), 
.N97(in[24]), .N101(in[25]), .N105(in[26]), .N109(in[27]), 
.N113(in[28]), .N117(in[29]), .N121(in[30]), .N125(in[31]), 
.N129(in[32]), .N130(in[33]), .N131(in[34]), .N132(in[35]), 
.N133(in[36]), .N134(in[37]), .N135(in[38]), .N136(in[39]), 
.N137(in[40]), .N724(out[0]), .N725(out[1]), .N726(out[2]), .N727(out[3]), 
.N728(out[4]), .N729(out[5]), .N730(out[6]), .N731(out[7]), 
.N732(out[8]), .N733(out[9]), .N734(out[10]), .N735(out[11]), 
.N736(out[12]), .N737(out[13]), .N738(out[14]), .N739(out[15]), 
.N740(out[16]), .N741(out[17]), .N742(out[18]), .N743(out[19]), 
.N744(out[20]), .N745(out[21]), .N746(out[22]), .N747(out[23]), 
.N748(out[24]), .N749(out[25]), .N750(out[26]), .N751(out[27]), 
.N752(out[28]), .N753(out[29]), .N754(out[30]), .N755(out[31]));

initial begin
   $readmemb(INPUT_FILE, memory);

   f = $fopen(OUTPUT_FILE);

   for (i = 0; i < NUMBER_OF_TESTS; i = i+1) begin
      in = memory[i];
      #1;
      $fdisplay(f, "%b", out);
   end
   $fclose(f);
   $finish;
end

endmodule