module alpha(input [7:0] V, input [7:0] vmin, input [7:0] H, output [7:0] res);
    wire [12:0] m;
    assign m = (V - vmin) * H[4:0];
    assign res = m[12:5];
endmodule

module vmin(input [7:0] S, input [7:0] V, output [7:0] res);

    wire [15:0] sv;
    wire [7:0] d;
    wire ismod;
    assign d = (8'd255 - S);
    assign sv = d * V;
    assign ismod = sv < 256;
    assign res = ismod ? (sv == 255 ? 1 : 0) : (sv[15:8] + ((sv - sv[15:8] * 255) >= 255));

endmodule

module hsvrgb(input [7:0] H, input [7:0] S, input [7:0] V, output [7:0] R, output [7:0] G, output [7:0] B);

    wire [7:0] mr, ar, vinc, vdec;
    wire [7:0] hc;
    wire [23:0] resbus;
    assign hc = H > 191 ? 191 : H;
    assign vinc = mr + ar;
    assign vdec = V - ar;
    assign R = resbus[23:16];
    assign G = resbus[15:8];
    assign B = resbus[7:0];
    assign resbus = hc > 31 ? (
        hc > 63 ? (
            hc > 95 ? (
                hc > 127 ? (
                    hc > 159 ? {V, mr, vdec} : {vinc, mr, V}
                ) : {mr, vdec, V}
            ) : {mr, V, vinc}
        ) : {vdec, V, mr}
    ) : {V, vinc, mr};

    vmin m(.S(S), .V(V), .res(mr));
    alpha a(.V(V), .vmin(mr), .H(hc), .res(ar));
    
    

endmodule


module main();

    reg clk, rst, b;
    reg [7:0] S, V, H;
    wire [7:0] R, G, B;
    wire out, ready;
    wire pos, neg;
    wire Q, Q1;
    wire [7:0] mr, ar;
    
    reg [3:0] dataCnt;
    reg [23:0] data [5:0];
    
    reg [5:0] clk64;
    
    wire [23:0] pixel;
    wire [1:0] address;
    
    always begin
        #10 clk <= ~clk;
    end
    
    vmin m(.S(S), .V(V), .res(mr));
    alpha a(.V(V), .vmin(mr), .H(H), .res(ar));
    hsvrgb cc(.H(H), .S(S), .V(V), .R(R), .G(G), .B(B));
    
    always @(posedge clk) begin
        clk64 <= clk64 + 1;
        if (H == 192) begin
            H <= 0;
        end else begin
            H <= H + 1;
        end
    end
    
    initial begin
        
        S <= 255;
        V <= 255;
        H <= 0;
        $dumpfile("hsvrgb.vcd");
        $dumpvars;
        dataCnt <= 0;
        clk64<= 0;
        b <= 1;
        clk <= 0;
        rst <= 1;
        #30 rst <= 0; clk64 <= 0;
        #1300 b <= 0;
        #200000 $finish;
    end
   
endmodule
