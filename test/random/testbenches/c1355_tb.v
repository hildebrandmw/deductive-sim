module c1355_tb();
parameter INPUT_WIDTH = 41;
parameter OUTPUT_WIDTH = 32;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c1355.txt";
string OUTPUT_FILE = "output_vectors/c1355.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c1355 UUT (.G1(in[0]), .G2(in[1]), .G3(in[2]), .G4(in[3]), 
.G5(in[4]), .G6(in[5]), .G7(in[6]), .G8(in[7]), 
.G9(in[8]), .G10(in[9]), .G11(in[10]), .G12(in[11]), 
.G13(in[12]), .G14(in[13]), .G15(in[14]), .G16(in[15]), 
.G17(in[16]), .G18(in[17]), .G19(in[18]), .G20(in[19]), 
.G21(in[20]), .G22(in[21]), .G23(in[22]), .G24(in[23]), 
.G25(in[24]), .G26(in[25]), .G27(in[26]), .G28(in[27]), 
.G29(in[28]), .G30(in[29]), .G31(in[30]), .G32(in[31]), 
.G33(in[32]), .G34(in[33]), .G35(in[34]), .G36(in[35]), 
.G37(in[36]), .G38(in[37]), .G39(in[38]), .G40(in[39]), 
.G41(in[40]), .G1324(out[0]), .G1325(out[1]), .G1326(out[2]), .G1327(out[3]), 
.G1328(out[4]), .G1329(out[5]), .G1330(out[6]), .G1331(out[7]), 
.G1332(out[8]), .G1333(out[9]), .G1334(out[10]), .G1335(out[11]), 
.G1336(out[12]), .G1337(out[13]), .G1338(out[14]), .G1339(out[15]), 
.G1340(out[16]), .G1341(out[17]), .G1342(out[18]), .G1343(out[19]), 
.G1344(out[20]), .G1345(out[21]), .G1346(out[22]), .G1347(out[23]), 
.G1348(out[24]), .G1349(out[25]), .G1350(out[26]), .G1351(out[27]), 
.G1352(out[28]), .G1353(out[29]), .G1354(out[30]), .G1355(out[31]));

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