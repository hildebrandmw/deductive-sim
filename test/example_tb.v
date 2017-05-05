module and_tb();

parameter INPUT_WIDTH      = 2;
parameter OUTPUT_WIDTH     = 1;
parameter NUMBER_OF_TESTS  = 4;


reg   [INPUT_WIDTH-1:0] in;
wire  [OUTPUT_WIDTH-1:0] out;

reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];


test_and UUT (.N1(in[0]), .N2(in[1]), .N3(out[0]));

initial begin
   $readmemb("input_vectors/test_and.txt", memory);

   f = $fopen("output_vectors/test_and.txt");

   for (i = 0; i < NUMBER_OF_TESTS; i = i+1) begin
      in = memory[i];
      #1;
      $fdisplay(f, "%b", out);
      $display(i);
   end
   $fclose(f);
   $finish;
end

endmodule
