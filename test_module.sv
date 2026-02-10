// test_module.sv
// Поддерживает 4 последних различных значения; приём на T, эффект на T+1.
module test_module
#(
    parameter DATA_W = 8
)
(
    input  logic                  clk_in,
    input  logic                  reset_in,   // синхронный активный высокий
    input  logic [DATA_W-1:0]     data_in,

    output logic [DATA_W-1:0]     out_0,
    output logic                  out_valid_0,
    output logic [DATA_W-1:0]     out_1,
    output logic                  out_valid_1,
    output logic [DATA_W-1:0]     out_2,
    output logic                  out_valid_2,
    output logic [DATA_W-1:0]     out_3,
    output logic                  out_valid_3
);

    // pipeline: захват входа (pipe1) -> перенос на следующий такт (pipe2)
    logic [DATA_W-1:0] pipe1_data, pipe2_data;
    logic pipe1_valid, pipe2_valid;

    // история: val0 — самое новое, val3 — самое старое; v* — флаги валидности
    logic [DATA_W-1:0] val0, val1, val2, val3;
    logic v0, v1, v2, v3;

    // регистровые выходы (стабильный снимок истории)
    logic [DATA_W-1:0] out_0_r, out_1_r, out_2_r, out_3_r;
    logic out_valid_0_r, out_valid_1_r, out_valid_2_r, out_valid_3_r;

    // временные next-state переменные (вычисляются блокирующими присваиваниями)
    logic [DATA_W-1:0] n_pipe1_data, n_pipe2_data;
    logic n_pipe1_valid, n_pipe2_valid;
    logic [DATA_W-1:0] n_val0, n_val1, n_val2, n_val3;
    logic n_v0, n_v1, n_v2, n_v3;
    logic [DATA_W-1:0] n_out_0, n_out_1, n_out_2, n_out_3;
    logic n_out_v0, n_out_v1, n_out_v2, n_out_v3;

    always_ff @(posedge clk_in) begin
        if (reset_in) begin
            // синхронный сброс
            pipe1_data <= '0; pipe1_valid <= 1'b0;
            pipe2_data <= '0; pipe2_valid <= 1'b0;

            val0 <= '0; val1 <= '0; val2 <= '0; val3 <= '0;
            v0 <= 1'b0; v1 <= 1'b0; v2 <= 1'b0; v3 <= 1'b0;

            out_0_r <= '0; out_valid_0_r <= 1'b0;
            out_1_r <= '0; out_valid_1_r <= 1'b0;
            out_2_r <= '0; out_valid_2_r <= 1'b0;
            out_3_r <= '0; out_valid_3_r <= 1'b0;
        end else begin
            // advance pipeline (next)
            n_pipe2_data  = pipe1_data;
            n_pipe2_valid = pipe1_valid;
            n_pipe1_data  = data_in;
            n_pipe1_valid = 1'b1;

            // default next-history = current-history
            n_val0 = val0; n_val1 = val1; n_val2 = val2; n_val3 = val3;
            n_v0 = v0; n_v1 = v1; n_v2 = v2; n_v3 = v3;

            // обновление истории при наличии значения в pipe2 (текущее pipe2_data)
            if (pipe2_valid) begin
                logic [DATA_W-1:0] newd;
                newd = pipe2_data;

                if (!n_v0) begin
                    n_val0 = newd; n_v0 = 1'b1;
                end
                else if (newd == n_val0) begin
                end
                else if (!n_v1) begin
                    n_val1 = n_val0; n_val0 = newd; n_v1 = 1'b1;
                end
                else if (newd == n_val1) begin
                    n_val1 = n_val0; n_val0 = newd;
                end
                else if (!n_v2) begin
                    n_val2 = n_val1; n_val1 = n_val0; n_val0 = newd; n_v2 = 1'b1;
                end
                else if (newd == n_val2) begin
                    n_val2 = n_val1; n_val1 = n_val0; n_val0 = newd;
                end
                else if (!n_v3) begin
                    n_val3 = n_val2; n_val2 = n_val1; n_val1 = n_val0; n_val0 = newd; n_v3 = 1'b1;
                end
                else if (newd == n_val3) begin
                    n_val3 = n_val2; n_val2 = n_val1; n_val1 = n_val0; n_val0 = newd;
                end
                else begin
                    n_val3 = n_val2; n_val2 = n_val1; n_val1 = n_val0; n_val0 = newd;
                end
            end

            // формирование next-outputs как снимка next-history
            n_out_0  = n_v0 ? n_val0 : '0;
            n_out_v0 = n_v0;
            n_out_1  = n_v1 ? n_val1 : '0;
            n_out_v1 = n_v1;
            n_out_2  = n_v2 ? n_val2 : '0;
            n_out_v2 = n_v2;
            n_out_3  = n_v3 ? n_val3 : '0;
            n_out_v3 = n_v3;

            // фиксируем next-state в регистрах (non-blocking)
            pipe1_data <= n_pipe1_data;
            pipe1_valid <= n_pipe1_valid;
            pipe2_data <= n_pipe2_data;
            pipe2_valid <= n_pipe2_valid;

            val0 <= n_val0; val1 <= n_val1; val2 <= n_val2; val3 <= n_val3;
            v0 <= n_v0; v1 <= n_v1; v2 <= n_v2; v3 <= n_v3;

            out_0_r <= n_out_0; out_valid_0_r <= n_out_v0;
            out_1_r <= n_out_1; out_valid_1_r <= n_out_v1;
            out_2_r <= n_out_2; out_valid_2_r <= n_out_v2;
            out_3_r <= n_out_3; out_valid_3_r <= n_out_v3;
        end
    end

    // выходы модуля
    assign out_0 = out_0_r; assign out_valid_0 = out_valid_0_r;
    assign out_1 = out_1_r; assign out_valid_1 = out_valid_1_r;
    assign out_2 = out_2_r; assign out_valid_2 = out_valid_2_r;
    assign out_3 = out_3_r; assign out_valid_3 = out_valid_3_r;

endmodule
