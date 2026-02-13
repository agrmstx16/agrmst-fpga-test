module test_module
#(
    parameter DATA_W = 8
)
(
    input  logic              clk_in,
    input  logic              reset_in,
    input  logic [DATA_W-1:0] data_in,
    output logic [DATA_W-1:0] out_0,
    output logic              out_valid_0,
    output logic [DATA_W-1:0] out_1,
    output logic              out_valid_1,
    output logic [DATA_W-1:0] out_2,
    output logic              out_valid_2,
    output logic [DATA_W-1:0] out_3,
    output logic              out_valid_3
);

logic [DATA_W-1:0] sample_q;
logic              sample_v_q;

logic [DATA_W-1:0] h0_q, h1_q, h2_q, h3_q;
logic              v0_q, v1_q, v2_q, v3_q;

logic [DATA_W-1:0] h0_d, h1_d, h2_d, h3_d;
logic              v0_d, v1_d, v2_d, v3_d;

logic [DATA_W-1:0] newd;

always_comb begin
    h0_d = h0_q; h1_d = h1_q; h2_d = h2_q; h3_d = h3_q;
    v0_d = v0_q; v1_d = v1_q; v2_d = v2_q; v3_d = v3_q;
    newd = sample_q;

    if (sample_v_q) begin
        if (v0_q && (newd == h0_q)) begin
        end else if (v1_q && (newd == h1_q)) begin
            h1_d = h0_q; h0_d = newd;
        end else if (v2_q && (newd == h2_q)) begin
            h2_d = h1_q; h1_d = h0_q; h0_d = newd;
        end else if (v3_q && (newd == h3_q)) begin
            h3_d = h2_q; h2_d = h1_q; h1_d = h0_q; h0_d = newd;
        end else begin
            if (!v0_q) begin
                h0_d = newd; v0_d = 1'b1;
            end else if (!v1_q) begin
                h1_d = h0_q; v1_d = 1'b1; h0_d = newd;
            end else if (!v2_q) begin
                h2_d = h1_q; v2_d = 1'b1; h1_d = h0_q; h0_d = newd;
            end else if (!v3_q) begin
                h3_d = h2_q; v3_d = 1'b1; h2_d = h1_q; h1_d = h0_q; h0_d = newd;
            end else begin
                h3_d = h2_q; h2_d = h1_q; h1_d = h0_q; h0_d = newd;
            end
        end
    end
end

always_ff @(posedge clk_in) begin
    if (reset_in) begin
        sample_q   <= '0;
        sample_v_q <= 1'b0;
        h0_q <= '0; h1_q <= '0; h2_q <= '0; h3_q <= '0;
        v0_q <= 1'b0; v1_q <= 1'b0; v2_q <= 1'b0; v3_q <= 1'b0;
    end else begin
        h0_q <= h0_d; h1_q <= h1_d; h2_q <= h2_d; h3_q <= h3_d;
        v0_q <= v0_d; v1_q <= v1_d; v2_q <= v2_d; v3_q <= v3_d;
        sample_q   <= data_in;
        sample_v_q <= 1'b1;
    end
end

always_comb begin
    out_0       = (v0_q) ? h0_q : '0; 
    out_valid_0 = v0_q;
    out_1       = (v1_q) ? h1_q : '0; 
    out_valid_1 = v1_q;
    out_2       = (v2_q) ? h2_q : '0; 
    out_valid_2 = v2_q;
    out_3       = (v3_q) ? h3_q : '0; 
    out_valid_3 = v3_q;
end

endmodule
