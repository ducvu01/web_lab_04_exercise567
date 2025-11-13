<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    request.setCharacterEncoding("UTF-8");

    String jdbcUrl = "jdbc:sqlserver://localhost:1434;databaseName=student_management;encrypt=false;trustServerCertificate=true";
    String dbUser = "sa";
    String dbPass = "sa";

    // parameters
    String idStr = request.getParameter("id");
    String studentCode = request.getParameter("student_code");
    String fullName = request.getParameter("full_name");
    String email = request.getParameter("email");
    String major = request.getParameter("major");

    if (studentCode != null) studentCode = studentCode.trim();
    if (fullName != null) fullName = fullName.trim();
    if (email != null) email = email.trim();
    if (major != null) major = major.trim();

    // validate id
    if (idStr == null) {
%>
<!doctype html><html><head><meta charset="UTF-8"><title>Error</title></head><body>
  <p style="color:red;font-weight:bold;">Invalid request: missing id.</p>
  <p><a href="list_students.jsp">Back to list</a></p>
</body></html>
<%
        return;
    }

    int id = -1;
    try {
        id = Integer.parseInt(idStr);
    } catch (NumberFormatException nfe) {
%>
<html><head><meta charset="UTF-8"><title>Error</title></head><body>
  <p style="color:red;font-weight:bold;">Invalid student id.</p>
  <p><a href="list_students.jsp">Back to list</a></p>
</body></html>
<%
        return;
    }

    // Server-side validation: full name required
    if (fullName == null || fullName.trim().isEmpty()) {
%>
<html><head><meta charset="UTF-8"><title>Error</title></head><body>
  <p style="color:red;font-weight:bold;">Required field missing: Full Name is required.</p>
  <p><a href="edit_student.jsp?id=<%= id %>">Back to Edit</a></p>
</body></html>
<%
        return;
    }

    // Patterns
    String codePattern = "^[A-Z]{2}[0-9]{3,}$";
    String emailPattern = "^[A-Za-z0-9+_.-]+@(.+)$";

    // Validate student code (readonly on form but still validate)
    if (studentCode == null || !studentCode.matches(codePattern)) {
%>
<html><head><meta charset="UTF-8"><title>Invalid Code</title></head><body>
  <p style="color:red;font-weight:bold;">Invalid Student Code format. Use 2 uppercase letters followed by 3 or more digits (e.g. SV001).</p>
  <p><a href="edit_student.jsp?id=<%= id %>">Back to Edit</a></p>
</body></html>
<%
        return;
    }

    // Email validation 
    if (email != null && !email.isEmpty()) {
        if (!email.matches(emailPattern)) {
%>
<html><head><meta charset="UTF-8"><title>Invalid Email</title></head><body>
  <p style="color:red;font-weight:bold;">Invalid email format. Please enter a valid email (e.g. john@example.com).</p>
  <p><a href="edit_student.jsp?id=<%= id %>">Back to Edit</a></p>
</body></html>
<%
                return;
            }
    }

    // Attempt update
    String updateSql = "UPDATE dbo.students SET full_name = ?, email = ?, major = ? WHERE id = ?";

    try {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
    } catch (ClassNotFoundException ce) {
        out.println("<p style='color:red;'>JDBC Driver not found. Put driver JAR in WEB-INF/lib.</p>");
        log("Driver error: " + ce.getMessage(), ce);
        return;
    }

    try (Connection conn = DriverManager.getConnection(jdbcUrl, dbUser, dbPass);
         PreparedStatement ps = conn.prepareStatement(updateSql)) {

        ps.setString(1, fullName.trim());

        if (email == null || email.trim().isEmpty()) {
            ps.setNull(2, Types.VARCHAR);
        } else {
            ps.setString(2, email.trim());
        }

        if (major == null || major.trim().isEmpty()) {
            ps.setNull(3, Types.VARCHAR);
        } else {
            ps.setString(3, major.trim());
        }

        ps.setInt(4, id);

        int affected = ps.executeUpdate();
        if (affected > 0) {
            response.sendRedirect("list_students.jsp?msg=" + java.net.URLEncoder.encode("Student updated successfully", "UTF-8"));
            return;
        } else {
            out.println("<p style='color:red;font-weight:bold;'>Update failed: student not found.</p>");
            out.println("<p><a href='list_students.jsp'>Back to list</a></p>");
            return;
        }

    } catch (SQLException se) {
        out.println("<p style='color:red;font-weight:bold;'>Database error. Please contact administrator.</p>");
        log("SQL error while updating student: " + se.getMessage(), se);
    }
%>
