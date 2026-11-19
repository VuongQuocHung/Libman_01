package libman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Librarian5;
import libman.model.Manager5;
import libman.model.Member5;
import libman.model.Reader5;
import libman.util.DBUtil;

public class MemberDAO5 {

    /**
     * Đăng nhập: trả về Reader5, Librarian5 hoặc Manager5 (tùy vai trò của tài khoản),
     * hoặc null nếu sai tên tài khoản hoặc mật khẩu.
     *
     * @param passwordHash mật khẩu đã băm SHA-256
     */
    public Member5 login(String username, String passwordHash) throws SQLException {
        // Một truy vấn lấy thông tin chung của thành viên và cho biết thành viên đó thuộc vai trò nào
        String sql = "SELECT " + MemberMapper.MEMBER_COLUMNS + ", "
                + "r.readerCode, "
                + "s.staffCode, s.position, s.startDate, "
                + "l.schedule, "
                + "mg.`level` AS managerLevel, "
                + "(r.id IS NOT NULL) AS isReader, "
                + "(l.id IS NOT NULL) AS isLibrarian, "
                + "(mg.id IS NOT NULL) AS isManager "
                + "FROM tblMember5 m "
                + "LEFT JOIN tblReader5 r ON r.id = m.id "
                + "LEFT JOIN tblStaff5 s ON s.id = m.id "
                + "LEFT JOIN tblLibrarian5 l ON l.id = m.id "
                + "LEFT JOIN tblManager5 mg ON mg.id = m.id "
                + "WHERE m.username = ? AND m.password = ?";

        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, passwordHash);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                // Tạo đúng loại đối tượng theo vai trò của thành viên
                if (rs.getBoolean("isReader")) {
                    Reader5 reader = new Reader5();
                    MemberMapper.fill(reader, rs);
                    reader.setReaderCode(rs.getString("readerCode"));
                    return reader;
                }

                if (rs.getBoolean("isLibrarian")) {
                    Librarian5 librarian = new Librarian5();
                    MemberMapper.fill(librarian, rs);
                    librarian.setStaffCode(rs.getString("staffCode"));
                    librarian.setPosition(rs.getString("position"));
                    librarian.setStartDate(rs.getDate("startDate"));
                    librarian.setSchedule(rs.getString("schedule"));
                    return librarian;
                }

                if (rs.getBoolean("isManager")) {
                    Manager5 manager = new Manager5();
                    MemberMapper.fill(manager, rs);
                    manager.setStaffCode(rs.getString("staffCode"));
                    manager.setPosition(rs.getString("position"));
                    manager.setStartDate(rs.getDate("startDate"));
                    manager.setLevel(rs.getString("managerLevel"));
                    return manager;
                }

                Member5 member = new Member5();
                MemberMapper.fill(member, rs);
                return member;
            }
        }
    }
}
