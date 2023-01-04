module sdramc #(
        parameter DATA_WD = 16,
        parameter ADDR_WD = 13,
        parameter COL_WD  = 10
    ) (
        input                           clk,
        input                           rst_n,

        input                           cmd_valid,
        input  [1 : 0]                  cmd,
        input  [ADDR_WD - 1 : 0]        row_addr,
        input  [COL_WD - 1 : 0]         col_addr,
        input  [1 : 0]                  cmd_ba,
        output reg                      cmd_ready,


        output                          Cke,
        output reg                      Cs_n,
        output reg                      Ras_n,
        output reg                      Cas_n,
        output reg                      We_n,
        
        output [DATA_WD - 1 : 0]        rdata,
        output [1 : 0]                  Dqm,
        output reg [ADDR_WD - 1 : 0]    Addr,
        output reg [1 : 0]              Ba,
        inout  [DATA_WD - 1 : 0]        Dq                  
    );

    localparam IDLE         = 0;
    localparam NOP          = 1;
    localparam PRECHARGE    = 2;
    localparam AUTO_REFRESH = 3;
    localparam LOAD_MODE_REG= 4;
    localparam ACTIVE       = 5;
    localparam READ         = 6;
    localparam WRITE        = 7;
    localparam TERMINATE    = 8;

    reg  [3 : 0]            cstate;
    reg  [3 : 0]            nstate;
    reg [14 : 0]            power_cnt;
    reg  [2 : 0]            t_cnt;
    reg [DATA_WD - 1 : 0]   wdata;
    reg                     w_last;
    reg                     w_fire;

    wire cmd_fire = cmd_valid && cmd_ready;

    assign Cke = 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdata <= 'b0;
        end
        else if (w_fire) begin
            wdata <= wdata + 1;
            if (w_last) begin
                wdata <= 'b0;
            end
        end
    end

    assign Dq = w_fire ? wdata : 'bz;
    assign rdata = Dq;

    // Write enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_fire <= 'b0;
        end
        else if (w_fire && !w_last) begin
            w_fire <= 1'b1;
        end
        else begin
            w_fire <= !We_n;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_last <= 'b0;
        end
        else if (t_cnt == 1) begin
            w_last <= 'b1;
        end
    end

    // Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            power_cnt <= 'b0;
        end
        else begin
            power_cnt <= power_cnt + 1;
            if (nstate == AUTO_REFRESH) begin
                power_cnt <= 0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_cnt <= 'b0;
        end
        else begin
            case (nstate)
                ACTIVE : t_cnt <= 'd2;

                WRITE  : t_cnt <= 'd7;

                READ   : t_cnt <= 'd3;

                PRECHARGE : t_cnt <= 'd2;

                default : t_cnt <= 'b0;
            endcase
            if (t_cnt != 0) begin
                t_cnt <= t_cnt - 1;
            end
            else begin
                t_cnt <= t_cnt;
            end
        end
    end

    // Commond
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_ready <= 'b0;
        end
        else if (nstate == LOAD_MODE_REG) begin
            cmd_ready <= 'b1;
        end
        else if (!t_cnt) begin
            cmd_ready <= 'b1;
        end
        else begin
            cmd_ready <= 'b0;
        end
    end

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cstate <= IDLE;
        end
        else begin
            cstate <= nstate;
        end
    end

    always @(*) begin
        case (cstate)
            IDLE : begin
                if (power_cnt == 'd10005) begin
                    nstate = NOP;
                end
            end
            NOP   : begin
                if (power_cnt == 'd10006) begin
                    nstate = PRECHARGE;
                end
                else begin
                    nstate = cmd_fire ? cmd : NOP;
                end
            end
            PRECHARGE : begin
                if (power_cnt == 'd10008) begin
                    nstate = AUTO_REFRESH;
                end
                else begin
                    nstate = cmd;
                end
            end
            AUTO_REFRESH : begin
                if (power_cnt == 'd10015) begin
                    nstate = AUTO_REFRESH;
                end
                else if (power_cnt == 'd10022) begin
                    nstate = LOAD_MODE_REG;
                end
                else begin
                    nstate = cmd;
                end
            end
            LOAD_MODE_REG : begin
                if (power_cnt == 'd10024) begin
                    nstate = NOP;
                end
                else begin
                    nstate = cmd;
                end
            end
            READ : nstate = NOP;

            WRITE : nstate = NOP;

            default : nstate = IDLE;
        endcase
    end

    always @(*) begin
        case (cstate)
            IDLE : begin
                Cs_n = 1;
            end

            NOP  : begin
                Cs_n  = 0;
                Ras_n = 1;
                Cas_n = 1;
                We_n  = 1;
            end

            ACTIVE : begin
                Cs_n  = 0;
                Ras_n = 0;
                Cas_n = 1;
                We_n  = 1;
            end

            READ : begin
                Cs_n  = 0;
                Ras_n = 1;
                Cas_n = 0;
                We_n  = 1;
            end

            WRITE : begin
                Cs_n  = 0;
                Ras_n = 1;
                Cas_n = 0;
                We_n  = 0;
            end

            PRECHARGE : begin
                Cs_n  = 0;
                Ras_n = 0;
                Cas_n = 1;
                We_n  = 0;
            end

            AUTO_REFRESH : begin
                Cs_n  = 0;
                Ras_n = 0;
                Cas_n = 0;
                We_n  = 1;
            end

            LOAD_MODE_REG : begin
                Cs_n  = 0;
                Ras_n = 0;
                Cas_n = 0;
                We_n  = 0;
            end

            default : begin
                Cs_n  = 0;
                Ras_n = 1;
                Cas_n = 1;
                We_n  = 1;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Addr <= 'b0;
            Ba <= 'b0;
        end
        else begin
            case (nstate)
                ACTIVE : begin
                    Addr <= row_addr;
                    Ba <= cmd_ba;
                end

                READ : begin
                    Addr <= col_addr;
                    Ba <= cmd_ba;
                end

                WRITE : begin
                    Addr <= col_addr;
                    Ba <= cmd_ba;
                end

                PRECHARGE : begin
                    Addr[10] <= row_addr[10];
                    Ba <= cmd_ba;
                end
                default : begin
                    Addr <= 'b0;
                    Ba <= 'b0;
                end
            endcase
        end
    end
endmodule

// 参数定义，代码可读性，尽量用参数替代常量
// 状态机第三步，组合与时序分开
// Addr Ba Dq需要寄存器赋值

// linux 正则表达式处理文本
// 脚本语言的作用是控制流程
