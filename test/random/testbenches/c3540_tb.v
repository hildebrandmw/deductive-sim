module c3540_tb();
parameter INPUT_WIDTH = 50;
parameter OUTPUT_WIDTH = 22;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c3540.txt";
string OUTPUT_FILE = "output_vectors/c3540.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c3540 UUT (.N1(in[0]), .N13(in[1]), .N20(in[2]), .N33(in[3]), 
.N41(in[4]), .N45(in[5]), .N50(in[6]), .N58(in[7]), 
.N68(in[8]), .N77(in[9]), .N87(in[10]), .N97(in[11]), 
.N107(in[12]), .N116(in[13]), .N124(in[14]), .N125(in[15]), 
.N128(in[16]), .N132(in[17]), .N137(in[18]), .N143(in[19]), 
.N150(in[20]), .N159(in[21]), .N169(in[22]), .N179(in[23]), 
.N190(in[24]), .N200(in[25]), .N213(in[26]), .N222(in[27]), 
.N223(in[28]), .N226(in[29]), .N232(in[30]), .N238(in[31]), 
.N244(in[32]), .N250(in[33]), .N257(in[34]), .N264(in[35]), 
.N270(in[36]), .N274(in[37]), .N283(in[38]), .N294(in[39]), 
.N303(in[40]), .N311(in[41]), .N317(in[42]), .N322(in[43]), 
.N326(in[44]), .N329(in[45]), .N330(in[46]), .N343(in[47]), 
.N349(in[48]), .N350(in[49]), .N1713(out[0]), .N1947(out[1]), .N3195(out[2]), .N3833(out[3]), 
.N3987(out[4]), .N4028(out[5]), .N4145(out[6]), .N4589(out[7]), 
.N4667(out[8]), .N4815(out[9]), .N4944(out[10]), .N5002(out[11]), 
.N5045(out[12]), .N5047(out[13]), .N5078(out[14]), .N5102(out[15]), 
.N5120(out[16]), .N5121(out[17]), .N5192(out[18]), .N5231(out[19]), 
.N5360(out[20]), .N5361(out[21]));
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