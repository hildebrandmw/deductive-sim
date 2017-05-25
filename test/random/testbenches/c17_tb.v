module c17_tb();
parameter INPUT_WIDTH = 5;
parameter OUTPUT_WIDTH = 2;
parameter NUMBER_OF_TESTS = 32;
string INPUT_FILE = "input_vectors/c17.txt";
string OUTPUT_FILE = "output_vectors/c17.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

c17 UUT (.N1(in[0]), .N2(in[1]), .N3(in[2]), .N6(in[3]), 
.N7(in[4]), .N22(out[0]), .N23(out[1]));
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