<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    request.setCharacterEncoding("UTF-8");
    String jdbcUrl = "jdbc:sqlserver://localhost:1434;databaseName=student_management;encrypt=false;trustServerCertificate=true";
    String dbUser = "sa";
    String dbPass = "sa";

    String[] ids = request.getParameterValues("ids");
    if (ids == null || ids.length == 0) {
%>
    <!doctype html><html><head><meta charset="UTF-8"><title>No Selection</title></head><body>
      <p style="color:red;font-weight:bold;">No students selected.</p>
      <p><a href="list_students.jsp">Back to list</a></p>
    </body></html>
<%
        return;
    }

    // Validate and build integer list
    List<Integer> idList = new ArrayList<>();
    try {
        for (String s : ids) {
            idList.add(Integer.parseInt(s));
        }
    } catch (NumberFormatException nfe) {
%>
    <!doctype html><html><head><meta charset="UTF-8"><title>Error</title></head><body>
      <p style="color:red;font-weight:bold;">Invalid id in selection.</p>
      <p><a href="list_students.jsp">Back to list</a></p>
    </body></html>
<%
        return;
    }

    // build placeholders
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < idList.size(); i++) {
        if (i > 0) sb.append(",");
        sb.append("?");
    }
    String sql = "DELETE FROM dbo.students WHERE id IN (" + sb.toString() + ")";

    try {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
    } catch (ClassNotFoundException e) {
        out.println("<p style='color:red;'>JDBC Driver not found</p>");
        return;
    }

    try (Connection conn = DriverManager.getConnection(jdbcUrl, dbUser, dbPass);
         PreparedStatement ps = conn.prepareStatement(sql)) {
        int idx = 1;
        for (Integer i : idList) ps.setInt(idx++, i);
        int affected = ps.executeUpdate();
        String msg = java.net.URLEncoder.encode(affected + " student(s) deleted", "UTF-8");
        response.sendRedirect("list_students.jsp?msg=" + msg);
        return;
    } catch (SQLException se) {
        out.println("<p style='color:red;font-weight:bold;'>Database error. Please contact admin.</p>");
        log("SQL error in bulk delete: " + se.getMessage(), se);
    }
%>
