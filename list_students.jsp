<%@ page import="java.sql.*, java.net.URLEncoder, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    request.setCharacterEncoding("UTF-8");

    String jdbcUrl = "jdbc:sqlserver://localhost:1434;databaseName=student_management;encrypt=false;trustServerCertificate=true";
    String dbUser = "sa";
    String dbPass = "sa";

    // --- Pagination & search & sorting params ---
    String pageParam = request.getParameter("page");
    int currentPage = 1;
    try { if (pageParam != null) currentPage = Math.max(1, Integer.parseInt(pageParam)); } catch (NumberFormatException e) { currentPage = 1; }

    final int recordsPerPage = 10;
    int offset = (currentPage - 1) * recordsPerPage;

    String keyword = request.getParameter("keyword");
    if (keyword != null) keyword = keyword.trim();
    boolean hasKeyword = (keyword != null && !keyword.isEmpty());

    // Sorting: allow only safe columns
    String sortBy = request.getParameter("sort");
    String order = request.getParameter("order");
    Set<String> allowedSort = new HashSet<>(Arrays.asList("id","student_code","full_name","created_at","major"));
    if (sortBy == null || !allowedSort.contains(sortBy)) sortBy = "id";
    if (order == null || !(order.equalsIgnoreCase("asc") || order.equalsIgnoreCase("desc"))) order = "desc";

	// success and error message
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");

    // Count SQL
    String countSql;
    // Select SQL with offset
    String selectSql;

    if (hasKeyword) {
        countSql = "SELECT COUNT(*) FROM dbo.students WHERE full_name LIKE ? OR student_code LIKE ? OR major LIKE ?";
        selectSql = "SELECT id, student_code, full_name, email, major, created_at FROM dbo.students " +
                    "WHERE full_name LIKE ? OR student_code LIKE ? OR major LIKE ? " +
                    "ORDER BY " + sortBy + " " + order + " OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
    } else {
        countSql = "SELECT COUNT(*) FROM dbo.students";
        selectSql = "SELECT id, student_code, full_name, email, major, created_at FROM dbo.students " +
                    "ORDER BY " + sortBy + " " + order + " OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
    }

    // Load driver
    try {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
    } catch (ClassNotFoundException e) {
        out.println("<p style='color:red;font-weight:bold;'>JDBC Driver not found. Put Microsoft JDBC driver JAR in WEB-INF/lib.</p>");
        log("Driver error: " + e.getMessage(), e);
        return;
    }

    int totalRecords = 0;
    int totalPages = 1;

    // Get totalRecords
    try (Connection conn = DriverManager.getConnection(jdbcUrl, dbUser, dbPass)) {

        if (hasKeyword) {
            try (PreparedStatement cp = conn.prepareStatement(countSql)) {
                String like = "%" + keyword + "%";
                cp.setString(1, like);
                cp.setString(2, like);
                cp.setString(3, like);
                try (ResultSet r = cp.executeQuery()) {
                    if (r.next()) totalRecords = r.getInt(1);
                }
            }
        } else {
            try (PreparedStatement cp = conn.prepareStatement(countSql);
                 ResultSet r = cp.executeQuery()) {
                if (r.next()) totalRecords = r.getInt(1);
            }
        }

        totalPages = (int) Math.ceil((double) totalRecords / recordsPerPage);
        if (totalPages == 0) totalPages = 1;
%>
<!doctype html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Student List</title>
  <style>
    body{font-family:Arial; padding:16px;}
    .search { margin-bottom: 12px; }
    input[type="text"]{ padding:6px; width:280px; }
    button, .clear-link { padding:6px 10px; margin-left:6px; }
    .msg { background:#e6ffea; color: #1b7a32; padding:8px; border-radius:4px; display:inline-block; margin-bottom:8px; }
    .error { background:#ffe6e6; color:#9b1b1b; padding:8px; border-radius:4px; display:inline-block; margin-bottom:8px; }
    .msg .icon, .error .icon { margin-right:6px; font-weight:bold; }
    .table-responsive { overflow-x:auto; }
    table { border-collapse: collapse; width: 100%; max-width: 1200px; }
    th, td { border: 1px solid #ccc; padding: 8px; text-align: left; white-space: nowrap; }
    th { background: #f5f5f5; cursor:pointer; }
    .delete-link { color: red; }
    .pagination { margin-top:12px; }
    .pagination a { margin-right:6px; text-decoration:none; }
    .pagination strong { margin-right:6px; }
    @media (max-width: 768px) {
        table { font-size:12px; }
        th, td { padding:5px; }
    }
  </style>
  <script>
    // hide messages after 3s
    window.addEventListener('DOMContentLoaded', function() {
      setTimeout(function() {
        var msgs = document.querySelectorAll('.message');
        msgs.forEach(function(m){ m.style.display = 'none'; });
      }, 3000);
    });

    // prevent double submit / show processing
    function submitForm(form) {
      var btn = form.querySelector('button[type="submit"], input[type="submit"]');
      if (btn) {
        btn.disabled = true;
        btn.textContent = 'Processing...';
      }
      return true;
    }

    // select all checkboxes
    function toggleSelectAll(source) {
      var checks = document.querySelectorAll('input[name="ids"]');
      checks.forEach(function(c){ c.checked = source.checked; });
    }
  </script>
</head>
<body>
  <h2>Student List</h2>

  <!-- messages -->
  <%
      if (msg != null && !msg.isEmpty()) {
  %>
      <div class="msg message"><span class="icon">✓</span><%= java.net.URLDecoder.decode(msg, "UTF-8") %></div>
  <%
      }
      if (error != null && !error.isEmpty()) {
  %>
      <div class="error message"><span class="icon">✗</span><%= java.net.URLDecoder.decode(error, "UTF-8") %></div>
  <%
      }
  %>

  <form action="list_students.jsp" method="GET" class="search" onsubmit="return submitForm(this);">
    <input type="text" name="keyword" placeholder="Search by name, code or major..." value="<%= hasKeyword ? keyword : "" %>" />
    <button type="submit">Search</button>
    <a class="clear-link" href="list_students.jsp">Clear</a>

    <input type="hidden" name="sort" value="<%= sortBy %>" />
    <input type="hidden" name="order" value="<%= order %>" />
  </form>

  <div style="margin-bottom:8px;">
    <a href="export_csv.jsp<%= (hasKeyword ? "?keyword=" + URLEncoder.encode(keyword, "UTF-8") + "&sort=" + sortBy + "&order=" + order : "?sort=" + sortBy + "&order=" + order) %>">Export CSV</a>
  </div>

  <form action="delete_selected.jsp" method="post" onsubmit="return confirm('Are you sure you want to delete selected students?');">
    <div class="table-responsive">
      <table>
        <thead>
          <tr>
            <th><input type="checkbox" onclick="toggleSelectAll(this)" /></th>
            <th><a href="list_students.jsp?page=1&sort=id&order=<%= sortBy.equals("id") && order.equalsIgnoreCase("asc") ? "desc" : "asc" %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>">ID</a></th>
            <th><a href="list_students.jsp?page=1&sort=student_code&order=<%= sortBy.equals("student_code") && order.equalsIgnoreCase("asc") ? "desc" : "asc" %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>">Student Code</a></th>
            <th><a href="list_students.jsp?page=1&sort=full_name&order=<%= sortBy.equals("full_name") && order.equalsIgnoreCase("asc") ? "desc" : "asc" %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>">Full Name</a></th>
            <th>Email</th>
            <th><a href="list_students.jsp?page=1&sort=major&order=<%= sortBy.equals("major") && order.equalsIgnoreCase("asc") ? "desc" : "asc" %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>">Major</a></th>
            <th><a href="list_students.jsp?page=1&sort=created_at&order=<%= sortBy.equals("created_at") && order.equalsIgnoreCase("asc") ? "desc" : "asc" %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>">Created At</a></th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
<%
        // run select and render rows
        try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
            int paramIndex = 1;
            if (hasKeyword) {
                String like = "%" + keyword + "%";
                ps.setString(paramIndex++, like);
                ps.setString(paramIndex++, like);
                ps.setString(paramIndex++, like);
            }
            ps.setInt(paramIndex++, offset);
            ps.setInt(paramIndex++, recordsPerPage);

            try (ResultSet rs = ps.executeQuery()) {
                boolean hasRows = false;
                while (rs.next()) {
                    hasRows = true;
%>
          <tr>
            <td><input type="checkbox" name="ids" value="<%= rs.getInt("id") %>" /></td>
            <td><%= rs.getInt("id") %></td>
            <td><%= rs.getString("student_code") %></td>
            <td><%= rs.getString("full_name") %></td>
            <td><%= rs.getString("email") %></td>
            <td><%= rs.getString("major") %></td>
            <td><%= rs.getTimestamp("created_at") %></td>
            <td>
              <a href="edit_student.jsp?id=<%= rs.getInt("id") %>">Edit</a>
              &nbsp;|&nbsp;
              <a href="delete_student.jsp?id=<%= rs.getInt("id") %>" class="delete-link"
                 onclick="return confirm('Are you sure you want to delete this student?')">Delete</a>
            </td>
          </tr>
<%
                } // end while
                if (!hasRows) {
%>
          <tr><td colspan="8">No students found.</td></tr>
<%
                }
            } // end rs
        } // end ps
    } // end connection try
    catch (SQLException ex) {
        out.println("<tr><td colspan='8' class='error'>Database error. Please contact admin.</td></tr>");
        log("SQL error while fetching students: " + ex.getMessage(), ex);
    }
%>
        </tbody>
      </table>
    </div>

    <div style="margin-top:8px;">
      <button type="submit">Delete Selected</button>
    </div>
  </form>

  <!-- Pagination links -->
  <div class="pagination">
    <% if (currentPage > 1) { %>
      <a href="list_students.jsp?page=<%= currentPage - 1 %>&sort=<%= sortBy %>&order=<%= order %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>">Previous</a>
    <% } %>

    <% for (int i = 1; i <= totalPages; i++) {
         if (i == currentPage) { %>
           <strong><%= i %></strong>
    <%   } else { %>
           <a href="list_students.jsp?page=<%= i %>&sort=<%= sortBy %>&order=<%= order %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>"><%= i %></a>
    <%   }
       } %>

    <% if (currentPage < totalPages) { %>
      <a href="list_students.jsp?page=<%= currentPage + 1 %>&sort=<%= sortBy %>&order=<%= order %><%= hasKeyword ? "&keyword=" + URLEncoder.encode(keyword, "UTF-8") : "" %>">Next</a>
    <% } %>
  </div>

</body>
</html>
