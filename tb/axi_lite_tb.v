module axi_lite_tb();
    localparam DATA_WD = 8;
    localparam ADDR_WD = 8;
    localparam DATA_ADDR_BYTE_WD = (DATA_WD + ADDR_WD) >> 3;
    localparam ADDR_BYTE_WD = ADDR_WD >> 3;
    localparam DATA_BYTE_WD = DATA_WD >> 3;

    reg                             clk;
    reg                             rst_n;

    reg                             tvalid;
    reg [ADDR_WD + DATA_WD - 1 : 0] tdata;
    reg [DATA_ADDR_BYTE_WD - 1 : 0] tkeep;
    wire                            tready;

    wire  [ADDR_WD - 1 : 0]         awaddr;
    wire                            awvalid;
    wire                            awready;

    wire  [DATA_WD - 1 : 0]         wdata;
    wire                            wvalid;
    wire                            wready;

    wire                            bvalid;
    wire [1 : 0]                    brsp;
    wire                            bready;

    wire [ADDR_WD - 1 : 0]          araddr;
    wire                            arvalid;
    wire                            arready;

    wire [1 : 0]                    rrsp;
    wire [DATA_WD - 1 : 0]          rdata;
    wire                            rvalid;
    wire                            rready;

    AXI_lite_master #(.DATA_WD(DATA_WD),.ADDR_WD(ADDR_WD),.DATA_ADDR_BYTE_WD(DATA_ADDR_BYTE_WD))
    AXI_lite_master(
        .clk        (clk),
        .rst_n      (rst_n),

        .tvalid     (tvalid),
        .tdata      (tdata),
        .tkeep      (tkeep),
        .tready     (tready),

        .awvalid    (awvalid),
        .awaddr     (awaddr),
        .awready    (awready),

        .wvalid     (wvalid),
        .wdata      (wdata),
        .wready     (wready),

        .bvalid     (bvalid),
        .bready     (bready),
        .brsp       (brsp),

        .arvalid    (arvalid),
        .arready    (arready),
        .araddr     (araddr),

        .rvalid     (rvalid),
        .rready     (rready),
        .rdata      (rdata),
        .rrsp       (rrsp)
    );

    AXI_lite_slave #(.DATA_WD(DATA_WD),.ADDR_WD(ADDR_WD))   
    AXI_lite_slave(
        .clk        (clk),
        .rst_n      (rst_n),

        .awvalid    (awvalid),
        .awaddr     (awaddr),
        .awready    (awready),

        .wvalid     (wvalid),
        .wdata      (wdata),
        .wready     (wready),

        .bvalid     (bvalid),
        .bready     (bready),
        .brsp       (brsp),

        .arvalid    (arvalid),
        .arready    (arready),
        .araddr     (araddr),

        .rvalid     (rvalid),
        .rready     (rready),
        .rdata      (rdata),
        .rrsp       (rrsp)
    );  

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
              rst_n = 0;
        #50   rst_n = 1;
        #30000 $finish;
    end

    localparam RANDOM = 1'b0;

    reg  [ADDR_WD : 0]  cnt_r;
    wire [ADDR_WD : 0] next_cnt_r;
    wire next_write_cmd = !next_cnt_r[ADDR_WD];
    wire t_fire = tvalid && tready;

    assign next_cnt_r = cnt_r + t_fire;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_r  <= 'b0;
            tvalid <= 'b0;
            tkeep  <= 'b0;
        end
        else begin
            cnt_r <= next_cnt_r;
            tkeep <= next_write_cmd ? {DATA_ADDR_BYTE_WD{1'b1}} : {{ADDR_BYTE_WD{1'b1}}, {DATA_BYTE_WD{1'b0}}};
            if (RANDOM) begin
                if (!tvalid || tready) begin
                    tvalid <= $random;
                end
            end 
            else begin
                tvalid <= 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            tdata <= 'b0;
        end
        else if (t_fire) begin
            tdata <= tdata + 9'b1_0000_0001;
            if (tdata == 16'hffff)
                tdata <= 16'h0;
        end
    end
endmodule
