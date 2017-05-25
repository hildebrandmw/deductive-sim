module mux(a,s,b,z);
input a, s, b;
output z;

wire s3, c, d;

not NOT1    (s3, s);
and AND2_1  (c, s3, a);
and AND2_2  (d, s, b);
or  OR2_1   (z, c, d);

endmodule
