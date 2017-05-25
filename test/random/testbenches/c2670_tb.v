module c2670_tb();
parameter INPUT_WIDTH = 233;
parameter OUTPUT_WIDTH = 140;
parameter NUMBER_OF_TESTS = 10000;
string INPUT_FILE = "input_vectors/c2670.txt";
string OUTPUT_FILE = "output_vectors/c2670.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c2670 UUT (.N1(in[0]), .N2(in[1]), .N3(in[2]), .N4(in[3]), 
.N5(in[4]), .N6(in[5]), .N7(in[6]), .N8(in[7]), 
.N11(in[8]), .N14(in[9]), .N15(in[10]), .N16(in[11]), 
.N19(in[12]), .N20(in[13]), .N21(in[14]), .N22(in[15]), 
.N23(in[16]), .N24(in[17]), .N25(in[18]), .N26(in[19]), 
.N27(in[20]), .N28(in[21]), .N29(in[22]), .N32(in[23]), 
.N33(in[24]), .N34(in[25]), .N35(in[26]), .N36(in[27]), 
.N37(in[28]), .N40(in[29]), .N43(in[30]), .N44(in[31]), 
.N47(in[32]), .N48(in[33]), .N49(in[34]), .N50(in[35]), 
.N51(in[36]), .N52(in[37]), .N53(in[38]), .N54(in[39]), 
.N55(in[40]), .N56(in[41]), .N57(in[42]), .N60(in[43]), 
.N61(in[44]), .N62(in[45]), .N63(in[46]), .N64(in[47]), 
.N65(in[48]), .N66(in[49]), .N67(in[50]), .N68(in[51]), 
.N69(in[52]), .N72(in[53]), .N73(in[54]), .N74(in[55]), 
.N75(in[56]), .N76(in[57]), .N77(in[58]), .N78(in[59]), 
.N79(in[60]), .N80(in[61]), .N81(in[62]), .N82(in[63]), 
.N85(in[64]), .N86(in[65]), .N87(in[66]), .N88(in[67]), 
.N89(in[68]), .N90(in[69]), .N91(in[70]), .N92(in[71]), 
.N93(in[72]), .N94(in[73]), .N95(in[74]), .N96(in[75]), 
.N99(in[76]), .N100(in[77]), .N101(in[78]), .N102(in[79]), 
.N103(in[80]), .N104(in[81]), .N105(in[82]), .N106(in[83]), 
.N107(in[84]), .N108(in[85]), .N111(in[86]), .N112(in[87]), 
.N113(in[88]), .N114(in[89]), .N115(in[90]), .N116(in[91]), 
.N117(in[92]), .N118(in[93]), .N119(in[94]), .N120(in[95]), 
.N123(in[96]), .N124(in[97]), .N125(in[98]), .N126(in[99]), 
.N127(in[100]), .N128(in[101]), .N129(in[102]), .N130(in[103]), 
.N131(in[104]), .N132(in[105]), .N135(in[106]), .N136(in[107]), 
.N137(in[108]), .N138(in[109]), .N139(in[110]), .N140(in[111]), 
.N141(in[112]), .N142(in[113]), .N219(in[114]), .N224(in[115]), 
.N227(in[116]), .N230(in[117]), .N231(in[118]), .N234(in[119]), 
.N237(in[120]), .N241(in[121]), .N246(in[122]), .N253(in[123]), 
.N256(in[124]), .N259(in[125]), .N262(in[126]), .N263(in[127]), 
.N266(in[128]), .N269(in[129]), .N272(in[130]), .N275(in[131]), 
.N278(in[132]), .N281(in[133]), .N284(in[134]), .N287(in[135]), 
.N290(in[136]), .N294(in[137]), .N297(in[138]), .N301(in[139]), 
.N305(in[140]), .N309(in[141]), .N313(in[142]), .N316(in[143]), 
.N319(in[144]), .N322(in[145]), .N325(in[146]), .N328(in[147]), 
.N331(in[148]), .N334(in[149]), .N337(in[150]), .N340(in[151]), 
.N343(in[152]), .N346(in[153]), .N349(in[154]), .N352(in[155]), 
.N355(in[156]), .N143_I(in[157]), .N144_I(in[158]), .N145_I(in[159]), 
.N146_I(in[160]), .N147_I(in[161]), .N148_I(in[162]), .N149_I(in[163]), 
.N150_I(in[164]), .N151_I(in[165]), .N152_I(in[166]), .N153_I(in[167]), 
.N154_I(in[168]), .N155_I(in[169]), .N156_I(in[170]), .N157_I(in[171]), 
.N158_I(in[172]), .N159_I(in[173]), .N160_I(in[174]), .N161_I(in[175]), 
.N162_I(in[176]), .N163_I(in[177]), .N164_I(in[178]), .N165_I(in[179]), 
.N166_I(in[180]), .N167_I(in[181]), .N168_I(in[182]), .N169_I(in[183]), 
.N170_I(in[184]), .N171_I(in[185]), .N172_I(in[186]), .N173_I(in[187]), 
.N174_I(in[188]), .N175_I(in[189]), .N176_I(in[190]), .N177_I(in[191]), 
.N178_I(in[192]), .N179_I(in[193]), .N180_I(in[194]), .N181_I(in[195]), 
.N182_I(in[196]), .N183_I(in[197]), .N184_I(in[198]), .N185_I(in[199]), 
.N186_I(in[200]), .N187_I(in[201]), .N188_I(in[202]), .N189_I(in[203]), 
.N190_I(in[204]), .N191_I(in[205]), .N192_I(in[206]), .N193_I(in[207]), 
.N194_I(in[208]), .N195_I(in[209]), .N196_I(in[210]), .N197_I(in[211]), 
.N198_I(in[212]), .N199_I(in[213]), .N200_I(in[214]), .N201_I(in[215]), 
.N202_I(in[216]), .N203_I(in[217]), .N204_I(in[218]), .N205_I(in[219]), 
.N206_I(in[220]), .N207_I(in[221]), .N208_I(in[222]), .N209_I(in[223]), 
.N210_I(in[224]), .N211_I(in[225]), .N212_I(in[226]), .N213_I(in[227]), 
.N214_I(in[228]), .N215_I(in[229]), .N216_I(in[230]), .N217_I(in[231]), 
.N218_I(in[232]), .N398(out[0]), .N400(out[1]), .N401(out[2]), .N419(out[3]), 
.N420(out[4]), .N456(out[5]), .N457(out[6]), .N458(out[7]), 
.N487(out[8]), .N488(out[9]), .N489(out[10]), .N490(out[11]), 
.N491(out[12]), .N492(out[13]), .N493(out[14]), .N494(out[15]), 
.N792(out[16]), .N799(out[17]), .N805(out[18]), .N1026(out[19]), 
.N1028(out[20]), .N1029(out[21]), .N1269(out[22]), .N1277(out[23]), 
.N1448(out[24]), .N1726(out[25]), .N1816(out[26]), .N1817(out[27]), 
.N1818(out[28]), .N1819(out[29]), .N1820(out[30]), .N1821(out[31]), 
.N1969(out[32]), .N1970(out[33]), .N1971(out[34]), .N2010(out[35]), 
.N2012(out[36]), .N2014(out[37]), .N2016(out[38]), .N2018(out[39]), 
.N2020(out[40]), .N2022(out[41]), .N2387(out[42]), .N2388(out[43]), 
.N2389(out[44]), .N2390(out[45]), .N2496(out[46]), .N2643(out[47]), 
.N2644(out[48]), .N2891(out[49]), .N2925(out[50]), .N2970(out[51]), 
.N2971(out[52]), .N3038(out[53]), .N3079(out[54]), .N3546(out[55]), 
.N3671(out[56]), .N3803(out[57]), .N3804(out[58]), .N3809(out[59]), 
.N3851(out[60]), .N3875(out[61]), .N3881(out[62]), .N3882(out[63]), 
.N143_O(out[64]), .N144_O(out[65]), .N145_O(out[66]), .N146_O(out[67]), 
.N147_O(out[68]), .N148_O(out[69]), .N149_O(out[70]), .N150_O(out[71]), 
.N151_O(out[72]), .N152_O(out[73]), .N153_O(out[74]), .N154_O(out[75]), 
.N155_O(out[76]), .N156_O(out[77]), .N157_O(out[78]), .N158_O(out[79]), 
.N159_O(out[80]), .N160_O(out[81]), .N161_O(out[82]), .N162_O(out[83]), 
.N163_O(out[84]), .N164_O(out[85]), .N165_O(out[86]), .N166_O(out[87]), 
.N167_O(out[88]), .N168_O(out[89]), .N169_O(out[90]), .N170_O(out[91]), 
.N171_O(out[92]), .N172_O(out[93]), .N173_O(out[94]), .N174_O(out[95]), 
.N175_O(out[96]), .N176_O(out[97]), .N177_O(out[98]), .N178_O(out[99]), 
.N179_O(out[100]), .N180_O(out[101]), .N181_O(out[102]), .N182_O(out[103]), 
.N183_O(out[104]), .N184_O(out[105]), .N185_O(out[106]), .N186_O(out[107]), 
.N187_O(out[108]), .N188_O(out[109]), .N189_O(out[110]), .N190_O(out[111]), 
.N191_O(out[112]), .N192_O(out[113]), .N193_O(out[114]), .N194_O(out[115]), 
.N195_O(out[116]), .N196_O(out[117]), .N197_O(out[118]), .N198_O(out[119]), 
.N199_O(out[120]), .N200_O(out[121]), .N201_O(out[122]), .N202_O(out[123]), 
.N203_O(out[124]), .N204_O(out[125]), .N205_O(out[126]), .N206_O(out[127]), 
.N207_O(out[128]), .N208_O(out[129]), .N209_O(out[130]), .N210_O(out[131]), 
.N211_O(out[132]), .N212_O(out[133]), .N213_O(out[134]), .N214_O(out[135]), 
.N215_O(out[136]), .N216_O(out[137]), .N217_O(out[138]), .N218_O(out[139]));

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