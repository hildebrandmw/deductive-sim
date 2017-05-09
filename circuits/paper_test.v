module paper_test(a,s,b,z);

input a,b,s;
output z;

wire s, s3, c, d;

not G1 (s3, s);
and G2 (c, a, s3);
and G3 (d, s, b);
or  G4 (z, c, d);

endmodule
