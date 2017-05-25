module c432_tb();
parameter INPUT_WIDTH = 36;
parameter OUTPUT_WIDTH = 7;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c432.txt";
string OUTPUT_FILE = "output_vectors/c432.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c432 UUT (.N1(in[0]), .N4(in[1]), .N8(in[2]), .N11(in[3]), 
.N14(in[4]), .N17(in[5]), .N21(in[6]), .N24(in[7]), 
.N27(in[8]), .N30(in[9]), .N34(in[10]), .N37(in[11]), 
.N40(in[12]), .N43(in[13]), .N47(in[14]), .N50(in[15]), 
.N53(in[16]), .N56(in[17]), .N60(in[18]), .N63(in[19]), 
.N66(in[20]), .N69(in[21]), .N73(in[22]), .N76(in[23]), 
.N79(in[24]), .N82(in[25]), .N86(in[26]), .N89(in[27]), 
.N92(in[28]), .N95(in[29]), .N99(in[30]), .N102(in[31]), 
.N105(in[32]), .N108(in[33]), .N112(in[34]), .N115(in[35]), 
.N223(out[0]), .N329(out[1]), .N370(out[2]), .N421(out[3]), 
.N430(out[4]), .N431(out[5]), .N432(out[6]));
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