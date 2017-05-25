module c5315_tb();
parameter INPUT_WIDTH = 178;
parameter OUTPUT_WIDTH = 123;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c5315.txt";
string OUTPUT_FILE = "output_vectors/c5315.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c5315 UUT (.N1(in[0]), .N4(in[1]), .N11(in[2]), .N14(in[3]), 
.N17(in[4]), .N20(in[5]), .N23(in[6]), .N24(in[7]), 
.N25(in[8]), .N26(in[9]), .N27(in[10]), .N31(in[11]), 
.N34(in[12]), .N37(in[13]), .N40(in[14]), .N43(in[15]), 
.N46(in[16]), .N49(in[17]), .N52(in[18]), .N53(in[19]), 
.N54(in[20]), .N61(in[21]), .N64(in[22]), .N67(in[23]), 
.N70(in[24]), .N73(in[25]), .N76(in[26]), .N79(in[27]), 
.N80(in[28]), .N81(in[29]), .N82(in[30]), .N83(in[31]), 
.N86(in[32]), .N87(in[33]), .N88(in[34]), .N91(in[35]), 
.N94(in[36]), .N97(in[37]), .N100(in[38]), .N103(in[39]), 
.N106(in[40]), .N109(in[41]), .N112(in[42]), .N113(in[43]), 
.N114(in[44]), .N115(in[45]), .N116(in[46]), .N117(in[47]), 
.N118(in[48]), .N119(in[49]), .N120(in[50]), .N121(in[51]), 
.N122(in[52]), .N123(in[53]), .N126(in[54]), .N127(in[55]), 
.N128(in[56]), .N129(in[57]), .N130(in[58]), .N131(in[59]), 
.N132(in[60]), .N135(in[61]), .N136(in[62]), .N137(in[63]), 
.N140(in[64]), .N141(in[65]), .N145(in[66]), .N146(in[67]), 
.N149(in[68]), .N152(in[69]), .N155(in[70]), .N158(in[71]), 
.N161(in[72]), .N164(in[73]), .N167(in[74]), .N170(in[75]), 
.N173(in[76]), .N176(in[77]), .N179(in[78]), .N182(in[79]), 
.N185(in[80]), .N188(in[81]), .N191(in[82]), .N194(in[83]), 
.N197(in[84]), .N200(in[85]), .N203(in[86]), .N206(in[87]), 
.N209(in[88]), .N210(in[89]), .N217(in[90]), .N218(in[91]), 
.N225(in[92]), .N226(in[93]), .N233(in[94]), .N234(in[95]), 
.N241(in[96]), .N242(in[97]), .N245(in[98]), .N248(in[99]), 
.N251(in[100]), .N254(in[101]), .N257(in[102]), .N264(in[103]), 
.N265(in[104]), .N272(in[105]), .N273(in[106]), .N280(in[107]), 
.N281(in[108]), .N288(in[109]), .N289(in[110]), .N292(in[111]), 
.N293(in[112]), .N299(in[113]), .N302(in[114]), .N307(in[115]), 
.N308(in[116]), .N315(in[117]), .N316(in[118]), .N323(in[119]), 
.N324(in[120]), .N331(in[121]), .N332(in[122]), .N335(in[123]), 
.N338(in[124]), .N341(in[125]), .N348(in[126]), .N351(in[127]), 
.N358(in[128]), .N361(in[129]), .N366(in[130]), .N369(in[131]), 
.N372(in[132]), .N373(in[133]), .N374(in[134]), .N386(in[135]), 
.N389(in[136]), .N400(in[137]), .N411(in[138]), .N422(in[139]), 
.N435(in[140]), .N446(in[141]), .N457(in[142]), .N468(in[143]), 
.N479(in[144]), .N490(in[145]), .N503(in[146]), .N514(in[147]), 
.N523(in[148]), .N534(in[149]), .N545(in[150]), .N549(in[151]), 
.N552(in[152]), .N556(in[153]), .N559(in[154]), .N562(in[155]), 
.N566(in[156]), .N571(in[157]), .N574(in[158]), .N577(in[159]), 
.N580(in[160]), .N583(in[161]), .N588(in[162]), .N591(in[163]), 
.N592(in[164]), .N595(in[165]), .N596(in[166]), .N597(in[167]), 
.N598(in[168]), .N599(in[169]), .N603(in[170]), .N607(in[171]), 
.N610(in[172]), .N613(in[173]), .N616(in[174]), .N619(in[175]), 
.N625(in[176]), .N631(in[177]), .N709(out[0]), .N816(out[1]), .N1066(out[2]), .N1137(out[3]), 
.N1138(out[4]), .N1139(out[5]), .N1140(out[6]), .N1141(out[7]), 
.N1142(out[8]), .N1143(out[9]), .N1144(out[10]), .N1145(out[11]), 
.N1147(out[12]), .N1152(out[13]), .N1153(out[14]), .N1154(out[15]), 
.N1155(out[16]), .N1972(out[17]), .N2054(out[18]), .N2060(out[19]), 
.N2061(out[20]), .N2139(out[21]), .N2142(out[22]), .N2309(out[23]), 
.N2387(out[24]), .N2527(out[25]), .N2584(out[26]), .N2590(out[27]), 
.N2623(out[28]), .N3357(out[29]), .N3358(out[30]), .N3359(out[31]), 
.N3360(out[32]), .N3604(out[33]), .N3613(out[34]), .N4272(out[35]), 
.N4275(out[36]), .N4278(out[37]), .N4279(out[38]), .N4737(out[39]), 
.N4738(out[40]), .N4739(out[41]), .N4740(out[42]), .N5240(out[43]), 
.N5388(out[44]), .N6641(out[45]), .N6643(out[46]), .N6646(out[47]), 
.N6648(out[48]), .N6716(out[49]), .N6877(out[50]), .N6924(out[51]), 
.N6925(out[52]), .N6926(out[53]), .N6927(out[54]), .N7015(out[55]), 
.N7363(out[56]), .N7365(out[57]), .N7432(out[58]), .N7449(out[59]), 
.N7465(out[60]), .N7466(out[61]), .N7467(out[62]), .N7469(out[63]), 
.N7470(out[64]), .N7471(out[65]), .N7472(out[66]), .N7473(out[67]), 
.N7474(out[68]), .N7476(out[69]), .N7503(out[70]), .N7504(out[71]), 
.N7506(out[72]), .N7511(out[73]), .N7515(out[74]), .N7516(out[75]), 
.N7517(out[76]), .N7518(out[77]), .N7519(out[78]), .N7520(out[79]), 
.N7521(out[80]), .N7522(out[81]), .N7600(out[82]), .N7601(out[83]), 
.N7602(out[84]), .N7603(out[85]), .N7604(out[86]), .N7605(out[87]), 
.N7606(out[88]), .N7607(out[89]), .N7626(out[90]), .N7698(out[91]), 
.N7699(out[92]), .N7700(out[93]), .N7701(out[94]), .N7702(out[95]), 
.N7703(out[96]), .N7704(out[97]), .N7705(out[98]), .N7706(out[99]), 
.N7707(out[100]), .N7735(out[101]), .N7736(out[102]), .N7737(out[103]), 
.N7738(out[104]), .N7739(out[105]), .N7740(out[106]), .N7741(out[107]), 
.N7742(out[108]), .N7754(out[109]), .N7755(out[110]), .N7756(out[111]), 
.N7757(out[112]), .N7758(out[113]), .N7759(out[114]), .N7760(out[115]), 
.N7761(out[116]), .N8075(out[117]), .N8076(out[118]), .N8123(out[119]), 
.N8124(out[120]), .N8127(out[121]), .N8128(out[122]));
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