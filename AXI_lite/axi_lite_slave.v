module axi_lite_slave #(
        parameter DATA_WD = 8,
        parameter ADDR_WD = 8
    ) (
        input                       clk,
        input                       rst_n,

        input                       awvalid,
        input   [ADDR_WD - 1 : 0]   awaddr,
        output                      awready,

        input                       wvalid,
        input   [DATA_WD - 1 : 0]   wdata,
        output                      wready,

        output                      bvalid,
        output  [1 : 0]             brsp,
        input                       bready,

        input                       arvalid,
        input   [ADDR_WD - 1 : 0]   araddr,
        output                      arready,

        output                      rvalid,
        output  [DATA_WD - 1 : 0]   rdata,
        output  [1 : 0]             rrsp,
        input                       rready           
    );

    // Handshake 4 cases
    // !valid && !ready
    //  valid %% !ready     wait / pending
    // !valid &&  ready     ready / available
    //  valid &&  ready     fire

    // Handshake data changable next bit:
    // fire  || !valid
    // ready || !valid      non-blocking / wait

    localparam DEPTH = 1 << ADDR_WD;

    reg  [DATA_WD - 1 : 0]   mem [DEPTH - 1 : 0];
    reg                     awvalid_r;
    reg [ADDR_WD - 1 : 0]   awaddr_r;
    reg                     wvalid_r;
    reg [DATA_WD - 1 : 0]   wdata_r;
    reg                     bvalid_r;
    reg [DATA_WD - 1 : 0]   rdata_r;

    reg                     rvalid_r;

    wire aw_fire = awvalid && awready;
    wire  w_fire = wvalid && wready;
    wire  b_fire = bvalid && bready;
    wire ar_fire = arvalid && arready;
    wire  r_fire = rvalid && rready;

    wire hs_brsp_pending = bvalid && !bready;
    wire hs_rrsp_pending = rvalid && !rready;

    assign awready = !(hs_brsp_pending || awvalid_r);
    assign  wready = !(hs_brsp_pending || wvalid_r);
    assign arready = !hs_rrsp_pending;
    
    assign bvalid  = bvalid_r;

    assign rvalid  = rvalid_r;
    assign rdata   = rdata_r;

    assign brsp = 'b0;
    assign rrsp = 'b0;

    // write logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            awvalid_r <= 'b0;
            awaddr_r  <= 'b0;
            wvalid_r  <= 'b0;
            wdata_r   <= 'b0;
            bvalid_r  <= 'b0;
        end
        else begin
            if (aw_fire) begin
                awvalid_r <= awvalid;
                awaddr_r  <= awaddr;
            end
            if (w_fire) begin
                wvalid_r  <= wvalid;
                wdata_r   <= wdata;
            end
            if (b_fire) begin
                bvalid_r  <= 1'b0;
            end
            if (aw_fire && w_fire) begin
                mem[awaddr] <= wdata;
                awvalid_r   <= 1'b0;
                wvalid_r    <= 1'b0;
                bvalid_r    <= 1'b1;
            end
            else if (awvalid_r && w_fire) begin
                mem[awaddr_r] <= wdata;
                awvalid_r   <= 1'b0;
                wvalid_r    <= 1'b0;
                bvalid_r    <= 1'b1;
            end
            else if (aw_fire && wvalid_r) begin
                mem[awaddr] <= wdata_r;
                awvalid_r   <= 1'b0;
                wvalid_r    <= 1'b0;
                bvalid_r    <= 1'b1;
            end
        end
    end

    // read logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rvalid_r <= 'b0;
            rdata_r  <= 'b0;
        end
        else begin
            if (r_fire) begin
                rvalid_r <= 'b0;
            end
            if (ar_fire) begin
                rvalid_r <= 1'b1;
                rdata_r  <= mem[araddr];
            end
        end
    end
endmodule
