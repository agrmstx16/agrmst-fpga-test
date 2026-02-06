module test_module
#(
parameter DATA_W = 8
)
(
input logic clk_in,
input logic reset_in,
input logic [(DATA_W - 1) : 0] data_in,

output logic [(DATA_W - 1) : 0] out_0, 
output logic out_valid_0, 
output logic [(DATA_W - 1) : 0] out_1, 
output logic out_valid_1, 
output logic [(DATA_W - 1) : 0] out_2, 
output logic out_valid_2, 
output logic [(DATA_W - 1) : 0] out_3, 
output logic out_valid_3 
);

// Регистры пайплайна: двухтактная задержка приёма (pipe1 — захват на 1-м такте, pipe2 — доступ на 2-м)
logic [DATA_W-1:0] pipe1_data;
logic pipe1_valid;
logic [DATA_W-1:0] pipe2_data;
logic pipe2_valid;

// История последних 4 уникальных значений.
// val0 — самое новое; v0..v3 — флаги валидности соответствующих ячеек
logic [DATA_W-1:0] val0, val1, val2, val3;
logic v0, v1, v2, v3;

// Синхронный блок: синхронный сброс, сдвиг пайплайна и обновление истории.
// Важно: все присваивания здесь — non-blocking (<=), поведение определяется по фронту clk_in.
always_ff @(posedge clk_in) begin
    if (reset_in) begin
        pipe1_data <= '0;
        pipe1_valid <= 1'b0;
        pipe2_data <= '0;
        pipe2_valid <= 1'b0;
        val0 <= '0;
        val1 <= '0;
        val2 <= '0;
        val3 <= '0;
        v0 <= 1'b0;
        v1 <= 1'b0;
        v2 <= 1'b0;
        v3 <= 1'b0;
    end else begin
        // Сдвиг пайплайна: значение, захваченное в pipe1 на предыдущем фронте,
        // становится доступно в pipe2 на текущем фронте.
        pipe2_data <= pipe1_data;
        pipe2_valid <= pipe1_valid;
        pipe1_data <= data_in;
        pipe1_valid <= 1'b1;

        // Когда во второй стадии пайплайна есть валидное значение — обновляем историю.
        if (pipe2_valid) begin
            logic [DATA_W-1:0] newd;
            newd = pipe2_data;

            // Алгоритм обновления истории:
            // - если слот пустой — записать;
            // - если совпадает с уже имеющимся — продвинуть/не менять порядок;
            // - если уникальное и места нет — сдвинуть вниз и вставить новое в val0.
            if (!v0) begin
                val0 <= newd; v0 <= 1'b1;
            end
            else if (newd == val0) begin
                val0 <= val0;
            end
            else if (!v1) begin
                val1 <= val0;
                val0 <= newd;
                v1   <= 1'b1;
            end
            else if (newd == val1) begin
                val1 <= val0;
                val0 <= newd;
            end
            else if (!v2) begin
                val2 <= val1;
                val1 <= val0;
                val0 <= newd;
                v2   <= 1'b1;
            end
            else if (newd == val2) begin
                val2 <= val1;
                val1 <= val0;
                val0 <= newd;
            end
            else if (!v3) begin
                val3 <= val2;
                val2 <= val1;
                val1 <= val0;
                val0 <= newd;
                v3   <= 1'b1;
            end
            else if (newd == val3) begin
                val3 <= val2;
                val2 <= val1;
                val1 <= val0;
                val0 <= newd;
            end
            else begin
                val3 <= val2;
                val2 <= val1;
                val1 <= val0;
                val0 <= newd;
            end
        end
    end
end

// Выходы отражают текущее состояние истории; если слот не валиден — ноль и валидность = 0.
assign out_0 = (v0) ? val0 : '0;
assign out_valid_0 = v0;
assign out_1 = (v1) ? val1 : '0;
assign out_valid_1 = v1;
assign out_2 = (v2) ? val2 : '0;
assign out_valid_2 = v2;
assign out_3 = (v3) ? val3 : '0;
assign out_valid_3 = v3;

endmodule
