module c6288_tb();
parameter INPUT_WIDTH = 32;
parameter OUTPUT_WIDTH = 32;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c6288.txt";
string OUTPUT_FILE = "output_vectors/c6288.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c6288 UUT (.N1(in[0]), .N18(in[1]), .N35(in[2]), .N52(in[3]), 
.N69(in[4]), .N86(in[5]), .N103(in[6]), .N120(in[7]), 
.N137(in[8]), .N154(in[9]), .N171(in[10]), .N188(in[11]), 
.N205(in[12]), .N222(in[13]), .N239(in[14]), .N256(in[15]), 
.N273(in[16]), .N290(in[17]), .N307(in[18]), .N324(in[19]), 
.N341(in[20]), .N358(in[21]), .N375(in[22]), .N392(in[23]), 
.N409(in[24]), .N426(in[25]), .N443(in[26]), .N460(in[27]), 
.N477(in[28]), .N494(in[29]), .N511(in[30]), .N528(in[31]), 
.N545(out[0]), .N1581(out[1]), .N1901(out[2]), .N2223(out[3]), 
.N2548(out[4]), .N2877(out[5]), .N3211(out[6]), .N3552(out[7]), 
.N3895(out[8]), .N4241(out[9]), .N4591(out[10]), .N4946(out[11]), 
.N5308(out[12]), .N5672(out[13]), .N5971(out[14]), .N6123(out[15]), 
.N6150(out[16]), .N6160(out[17]), .N6170(out[18]), .N6180(out[19]), 
.N6190(out[20]), .N6200(out[21]), .N6210(out[22]), .N6220(out[23]), 
.N6230(out[24]), .N6240(out[25]), .N6250(out[26]), .N6260(out[27]), 
.N6270(out[28]), .N6280(out[29]), .N6287(out[30]), .N6288(out[31]));

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