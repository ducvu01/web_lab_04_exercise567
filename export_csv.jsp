<%@ page import="java.sql.*, java.net.URLEncoder" %>
<%@ page contentType="text/csv" pageEncoding="UTF-8" %>
<%
    request.setCharacterEncoding("UTF-8");
    String jdbcUrl = "jdbc:sqlserver://localhost:1434;databaseName=student_management;encrypt=false;trustServerCertificate=true";
    String dbUser = "sa";
    String dbPass = "sa";

    String keyword = request.getParameter("keyword");
    if (keyword != null) keyword = keyword.trim();
    boolean hasKeyword = (keyword != null && !keyword.isEmpty());

    String sortBy = request.getParameter("sort");
    String order = request.getParameter("order");
    if (sortBy == null) sortBy = "id";
    if (order == null) order = "desc";

    String sql;
    if (hasKeyword) {
        sql = "SELECT id, student_code, full_name, email, major, created_at FROM dbo.students WHERE full_name LIKE ? OR student_code LIKE ? OR major LIKE ? ORDER BY " + sortBy + " " + order;
    } else {
        sql = "SELECT id, student_code, full_name, email, major, created_at FROM dbo.students ORDER BY " + sortBy + " " + order;
    }

    response.setHeader("Content-Disposition", "attachment; filename=\"students.csv\"");
    out.println("ID,Student Code,Full Name,Email,Major,Created At");

    try {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
    } catch (ClassNotFoundException e) {
        out.println("ERROR: Driver not found");
        return;
    }

    try (Connection conn = DriverManager.getConnection(jdbcUrl, dbUser, dbPass);
         PreparedStatement ps = conn.prepareStatement(sql)) {

        if (hasKeyword) {
            String like = "%" + keyword + "%";
            ps.setString(1, like);
            ps.setString(2, like);
            ps.setString(3, like);
        }

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String line = rs.getInt("id") + "," +
                              "\"" + rs.getString("student_code") + "\"," +
                              "\"" + (rs.getString("full_name")!=null ? rs.getString("full_name").replace("\"","\"\"") : "") + "\"," +
                              "\"" + (rs.getString("email")!=null ? rs.getString("email").replace("\"","\"\"") : "") + "\"," +
                              "\"" + (rs.getString("major")!=null ? rs.getString("major").replace("\"","\"\"") : "") + "\"," +
                              rs.getTimestamp("created_at");
                out.println(line);
            }
        }
    } catch (SQLException ex) {
        out.println("ERROR: " + ex.getMessage());
    }
%>
