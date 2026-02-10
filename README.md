Описание:
- Модуль test_module реализует хранение 4 последних различных значений.
- Приём на такте T (pipe1), перенос в pipe2 на T+1, обновление истории/выходов на T+1.

Запуск теста:
iverilog -g2012 -Wall -o run_extra.vvp test_module.sv tb_extra.sv
vvp run_extra.vvp | tee run_extra.log
gtkwave tb_extra.vcd &
