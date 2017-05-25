module c880_tb();
parameter INPUT_WIDTH = 60;
parameter OUTPUT_WIDTH = 26;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c880.txt";
string OUTPUT_FILE = "output_vectors/c880.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c880 UUT (.N1(in[0]), .N8(in[1]), .N13(in[2]), .N17(in[3]), 
.N26(in[4]), .N29(in[5]), .N36(in[6]), .N42(in[7]), 
.N51(in[8]), .N55(in[9]), .N59(in[10]), .N68(in[11]), 
.N72(in[12]), .N73(in[13]), .N74(in[14]), .N75(in[15]), 
.N80(in[16]), .N85(in[17]), .N86(in[18]), .N87(in[19]), 
.N88(in[20]), .N89(in[21]), .N90(in[22]), .N91(in[23]), 
.N96(in[24]), .N101(in[25]), .N106(in[26]), .N111(in[27]), 
.N116(in[28]), .N121(in[29]), .N126(in[30]), .N130(in[31]), 
.N135(in[32]), .N138(in[33]), .N143(in[34]), .N146(in[35]), 
.N149(in[36]), .N152(in[37]), .N153(in[38]), .N156(in[39]), 
.N159(in[40]), .N165(in[41]), .N171(in[42]), .N177(in[43]), 
.N183(in[44]), .N189(in[45]), .N195(in[46]), .N201(in[47]), 
.N207(in[48]), .N210(in[49]), .N219(in[50]), .N228(in[51]), 
.N237(in[52]), .N246(in[53]), .N255(in[54]), .N259(in[55]), 
.N260(in[56]), .N261(in[57]), .N267(in[58]), .N268(in[59]), 
.N388(out[0]), .N389(out[1]), .N390(out[2]), .N391(out[3]), 
.N418(out[4]), .N419(out[5]), .N420(out[6]), .N421(out[7]), 
.N422(out[8]), .N423(out[9]), .N446(out[10]), .N447(out[11]), 
.N448(out[12]), .N449(out[13]), .N450(out[14]), .N767(out[15]), 
.N768(out[16]), .N850(out[17]), .N863(out[18]), .N864(out[19]), 
.N865(out[20]), .N866(out[21]), .N874(out[22]), .N878(out[23]), 
.N879(out[24]), .N880(out[25]));
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