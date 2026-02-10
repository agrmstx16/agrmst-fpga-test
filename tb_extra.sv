// tb_extra.sv
`timescale 1ns/1ps
module tb_extra;
    parameter DATA_W = 8;

    // Top-level interface to DUT
    reg clk_in;
    reg reset_in;
    reg [DATA_W-1:0] data_in;
    wire [DATA_W-1:0] out_0, out_1, out_2, out_3;
    wire out_valid_0, out_valid_1, out_valid_2, out_valid_3;

    // Instantiate DUT (module name must be test_module)
    test_module #(.DATA_W(DATA_W)) dut (
        .clk_in(clk_in),
        .reset_in(reset_in),
        .data_in(data_in),
        .out_0(out_0), .out_valid_0(out_valid_0),
        .out_1(out_1), .out_valid_1(out_valid_1),
        .out_2(out_2), .out_valid_2(out_valid_2),
        .out_3(out_3), .out_valid_3(out_valid_3)
    );

    // clock (10 ns period)
    initial begin
        clk_in = 0;
        forever #5 clk_in = ~clk_in;
    end

    // VCD
    initial begin
        $dumpfile("tb_extra.vcd");
        $dumpvars(0, tb_extra);
    end

    // ---------------- Reference model (2-stage pipeline semantics) --------------
    reg [DATA_W-1:0] ref_pipe1_data, ref_pipe2_data;
    reg ref_pipe1_v, ref_pipe2_v;
    reg [DATA_W-1:0] ref_val0, ref_val1, ref_val2, ref_val3;
    reg ref_v0, ref_v1, ref_v2, ref_v3;

    // reference: capture at T -> update history at T+1 when pipe2 valid
    always @(posedge clk_in) begin
        if (reset_in) begin
            ref_pipe1_data <= {DATA_W{1'b0}}; ref_pipe1_v <= 1'b0;
            ref_pipe2_data <= {DATA_W{1'b0}}; ref_pipe2_v <= 1'b0;
            ref_val0 <= {DATA_W{1'b0}}; ref_val1 <= {DATA_W{1'b0}};
            ref_val2 <= {DATA_W{1'b0}}; ref_val3 <= {DATA_W{1'b0}};
            ref_v0 <= 1'b0; ref_v1 <= 1'b0; ref_v2 <= 1'b0; ref_v3 <= 1'b0;
        end else begin
            // advance pipeline
            ref_pipe2_data <= ref_pipe1_data;
            ref_pipe2_v    <= ref_pipe1_v;
            ref_pipe1_data <= data_in;
            ref_pipe1_v    <= 1'b1;

            // update history on pipe2 valid
            if (ref_pipe2_v) begin
                reg [DATA_W-1:0] newd;
                newd = ref_pipe2_data;
                if (!ref_v0) begin
                    ref_val0 <= newd; ref_v0 <= 1'b1;
                end
                else if (newd == ref_val0) begin
                    // nothing
                end
                else if (!ref_v1) begin
                    ref_val1 <= ref_val0; ref_val0 <= newd; ref_v1 <= 1'b1;
                end
                else if (newd == ref_val1) begin
                    ref_val1 <= ref_val0; ref_val0 <= newd;
                end
                else if (!ref_v2) begin
                    ref_val2 <= ref_val1; ref_val1 <= ref_val0; ref_val0 <= newd; ref_v2 <= 1'b1;
                end
                else if (newd == ref_val2) begin
                    ref_val2 <= ref_val1; ref_val1 <= ref_val0; ref_val0 <= newd;
                end
                else if (!ref_v3) begin
                    ref_val3 <= ref_val2; ref_val2 <= ref_val1; ref_val1 <= ref_val0; ref_val0 <= newd; ref_v3 <= 1'b1;
                end
                else if (newd == ref_val3) begin
                    ref_val3 <= ref_val2; ref_val2 <= ref_val1; ref_val1 <= ref_val0; ref_val0 <= newd;
                end
                else begin
                    // shift down
                    ref_val3 <= ref_val2; ref_val2 <= ref_val1; ref_val1 <= ref_val0; ref_val0 <= newd;
                end
            end
        end
    end

    // ---------------- Test sequences ----------------
    reg [DATA_W-1:0] s_example1 [0:6]; // 1 2 1 2 1 2 1
    reg [DATA_W-1:0] s_example2 [0:9]; // example 2 from TЗ
    reg [DATA_W-1:0] s_repeat  [0:4];  // repeated same
    reg [DATA_W-1:0] s_alt     [0:7];  // alternating 5 and 6 etc
    reg [DATA_W-1:0] s_uniques [0:7];  // >4 uniques
    reg [DATA_W-1:0] s_zero    [0:3];  // zeros as data
    reg [DATA_W-1:0] s_rand    [0:63]; // random pool
    integer i;

    initial begin
        // fill directed sequences
        s_example1[0]=8'd1; s_example1[1]=8'd2; s_example1[2]=8'd1; s_example1[3]=8'd2;
        s_example1[4]=8'd1; s_example1[5]=8'd2; s_example1[6]=8'd1;

        s_example2[0]=8'd1; s_example2[1]=8'd2; s_example2[2]=8'd3; s_example2[3]=8'd4;
        s_example2[4]=8'd3; s_example2[5]=8'd2; s_example2[6]=8'd3; s_example2[7]=8'd4;
        s_example2[8]=8'd3; s_example2[9]=8'd4;

        s_repeat[0]=8'd7; s_repeat[1]=8'd7; s_repeat[2]=8'd7; s_repeat[3]=8'd7; s_repeat[4]=8'd7;

        s_alt[0]=8'd5; s_alt[1]=8'd6; s_alt[2]=8'd5; s_alt[3]=8'd6; s_alt[4]=8'd5; s_alt[5]=8'd6; s_alt[6]=8'd5; s_alt[7]=8'd6;

        s_uniques[0]=8'd10; s_uniques[1]=8'd11; s_uniques[2]=8'd12; s_uniques[3]=8'd13;
        s_uniques[4]=8'd14; s_uniques[5]=8'd15; s_uniques[6]=8'd9;  s_uniques[7]=8'd8;

        s_zero[0]=8'd0; s_zero[1]=8'd0; s_zero[2]=8'd1; s_zero[3]=8'd0;

        for (i=0;i<64;i=i+1) s_rand[i] = $urandom_range(0,15);
    end

    // task: send sequence from array (arr_id selects)
    task automatic send_from;
        input integer len;
        input integer arr_id; // 0..5 -> pick arrays, 6 -> random pool
        integer j;
        begin
            for (j=0; j<len; j=j+1) begin
                case (arr_id)
                    0: data_in = s_example1[j];
                    1: data_in = s_example2[j];
                    2: data_in = s_repeat[j];
                    3: data_in = s_alt[j];
                    4: data_in = s_uniques[j];
                    5: data_in = s_zero[j];
                    6: data_in = s_rand[j];
                    default: data_in = {DATA_W{1'b0}};
                endcase
                @(posedge clk_in);
            end
        end
    endtask

    // check task: compare DUT outputs to reference (called after waiting one extra posedge)
    task automatic check_match(input integer test_id);
        begin
            // allow non-blocking to settle
            #1;
            if ((out_valid_0 !== ref_v0) ||
                (out_valid_0 && (out_0 !== ref_val0)) ||
                (!out_valid_0 && (out_0 !== {DATA_W{1'b0}}))) begin
                $display("MISMATCH test=%0d out0 at %0t : dut(out0=%0d v=%b) ref(val0=%0d v=%b)",
                         test_id, $time, out_0, out_valid_0, ref_val0, ref_v0);
                $fatal;
            end
            if ((out_valid_1 !== ref_v1) ||
                (out_valid_1 && (out_1 !== ref_val1)) ||
                (!out_valid_1 && (out_1 !== {DATA_W{1'b0}}))) begin
                $display("MISMATCH test=%0d out1 at %0t : dut(out1=%0d v=%b) ref(val1=%0d v=%b)",
                         test_id, $time, out_1, out_valid_1, ref_val1, ref_v1);
                $fatal;
            end
            if ((out_valid_2 !== ref_v2) ||
                (out_valid_2 && (out_2 !== ref_val2)) ||
                (!out_valid_2 && (out_2 !== {DATA_W{1'b0}}))) begin
                $display("MISMATCH test=%0d out2 at %0t : dut(out2=%0d v=%b) ref(val2=%0d v=%b)",
                         test_id, $time, out_2, out_valid_2, ref_val2, ref_v2);
                $fatal;
            end
            if ((out_valid_3 !== ref_v3) ||
                (out_valid_3 && (out_3 !== ref_val3)) ||
                (!out_valid_3 && (out_3 !== {DATA_W{1'b0}}))) begin
                $display("MISMATCH test=%0d out3 at %0t : dut(out3=%0d v=%b) ref(val3=%0d v=%b)",
                         test_id, $time, out_3, out_valid_3, ref_val3, ref_v3);
                $fatal;
            end
            $display("OK test=%0d at %0t : out=[%0d(%b),%0d(%b),%0d(%b),%0d(%b)]",
                     test_id, $time, out_0, out_valid_0, out_1, out_valid_1, out_2, out_valid_2, out_3, out_valid_3);
        end
    endtask

    // ===== main driver =====
    integer t;
    initial begin
        // default
        data_in = {DATA_W{1'b0}};
        reset_in = 1;

        // hold reset for 2 clocks (synchronous)
        repeat (2) @(posedge clk_in);

        // release reset
        reset_in = 0;
        $display("RESET released at %0t", $time);

        // Test A: example1 (TЗ пример 1)
        $display("--- TEST A: example1 ---");
        send_from(7, 0);
        @(posedge clk_in); // allow last sample to propagate (T+1)
        check_match(1);

        // small gap
        repeat (2) @(posedge clk_in);

        // Test B: example2 (TЗ пример 2)
        $display("--- TEST B: example2 ---");
        send_from(10, 1);
        @(posedge clk_in);
        check_match(2);

        // Test C: repeats
        repeat (2) @(posedge clk_in);
        $display("--- TEST C: repeats ---");
        send_from(5, 2);
        @(posedge clk_in);
        check_match(3);

        // Test D: alternation
        repeat (2) @(posedge clk_in);
        $display("--- TEST D: alternation ---");
        send_from(8, 3);
        @(posedge clk_in);
        check_match(4);

        // Test E: many uniques (>4)
        repeat (2) @(posedge clk_in);
        $display("--- TEST E: many uniques ---");
        send_from(8, 4);
        @(posedge clk_in);
        check_match(5);

        // Test F: zeros as real data
        repeat (2) @(posedge clk_in);
        $display("--- TEST F: zeros as data ---");
        send_from(4, 5);
        @(posedge clk_in);
        check_match(6);

        // Test G: mid-sequence reset (send some, assert reset, then continue)
        repeat (2) @(posedge clk_in);
        $display("--- TEST G: mid-sequence reset ---");
        // send 3 values
        data_in = 8'd21; @(posedge clk_in);
        data_in = 8'd22; @(posedge clk_in);
        data_in = 8'd23; @(posedge clk_in);
        // now assert sync reset for 2 clocks
        reset_in = 1; repeat (2) @(posedge clk_in);
        // after reset release, send new sequence
        reset_in = 0;
        data_in = 8'd7; @(posedge clk_in);
        data_in = 8'd8; @(posedge clk_in);
        data_in = 8'd9; @(posedge clk_in);
        @(posedge clk_in);
        // check: history must reflect only 7,8,9 (earlier history wiped)
        // build small local ref for these three values to compare:
        // simpler: rely on check_match using ref-model which also reset cleared
        check_match(7);

        // Test H: random burst
        repeat (2) @(posedge clk_in);
        $display("--- TEST H: random burst (32 samples) ---");
        // fill random pool with deterministic seed
        for (t=0; t<32; t=t+1) s_rand[t] = $urandom_range(0,15);
        send_from(32, 6);
        @(posedge clk_in);
        check_match(8);

        // Stress: long random pipeline (64 samples), but make shorter for runtime
        repeat (2) @(posedge clk_in);
        $display("--- TEST I: stress random (64 samples) ---");
        for (t=0; t<64; t=t+1) s_rand[t] = $urandom_range(0,31);
        send_from(64, 6);
        @(posedge clk_in);
        check_match(9);

        $display("ALL TESTS PASSED (tb_extra)");
        $finish;
    end

endmodule
