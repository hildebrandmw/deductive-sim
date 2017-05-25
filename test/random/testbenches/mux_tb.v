module mux_tb();
parameter INPUT_WIDTH = 3;
parameter OUTPUT_WIDTH = 1;
parameter NUMBER_OF_TESTS = 8;
string INPUT_FILE = "input_vectors/mux.txt";
string OUTPUT_FILE = "output_vectors/mux.txt";

reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];
integer i,f;

mux UUT (.a(in[0]), .s(in[1]), .b(in[2]), .z(out[0]));
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