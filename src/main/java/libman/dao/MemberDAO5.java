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
     * Đăng nhập: trả về Reader5, Librarian5, Manager5 (tùy vai trò) hoặc null nếu sai tài khoản/mật khẩu.
     * @param passwordHash mật khẩu đã băm SHA-256
     */
    public Member5 login(String username, String passwordHash) throws SQLException {
        String sql = "SELECT " + MemberMapper.MEMBER_COLUMNS + ", "
                + "r.readerCode, r.registerDate, r.readerStatus, "
                + "s.staffCode, s.position, s.startDate, l.schedule, mg.`level` AS mgLevel, "
                + "(r.id IS NOT NULL) AS isReader, (l.id IS NOT NULL) AS isLibrarian, (mg.id IS NOT NULL) AS isManager "
                + "FROM tblMember5 m "
                + "LEFT JOIN tblReader5 r ON r.id = m.id "
                + "LEFT JOIN tblStaff5 s ON s.id = m.id "
                + "LEFT JOIN tblLibrarian5 l ON l.id = m.id "
                + "LEFT JOIN tblManager5 mg ON mg.id = m.id "
                + "WHERE m.username = ? AND m.password = ?";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, passwordHash);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                if (rs.getBoolean("isReader")) {
                    Reader5 r = new Reader5();
                    MemberMapper.fill(r, rs);
                    r.setReaderCode(rs.getString("readerCode"));
                    r.setRegisterDate(rs.getDate("registerDate"));
                    r.setReaderStatus(rs.getString("readerStatus"));
                    return r;
                }
                if (rs.getBoolean("isLibrarian")) {
                    Librarian5 l = new Librarian5();
                    MemberMapper.fill(l, rs);
                    l.setStaffCode(rs.getString("staffCode"));
                    l.setPosition(rs.getString("position"));
                    l.setStartDate(rs.getDate("startDate"));
                    l.setSchedule(rs.getString("schedule"));
                    return l;
                }
                if (rs.getBoolean("isManager")) {
                    Manager5 mg = new Manager5();
                    MemberMapper.fill(mg, rs);
                    mg.setStaffCode(rs.getString("staffCode"));
                    mg.setPosition(rs.getString("position"));
                    mg.setStartDate(rs.getDate("startDate"));
                    mg.setLevel(rs.getString("mgLevel"));
                    return mg;
                }
                Member5 m = new Member5();
                MemberMapper.fill(m, rs);
                return m;
            }
        }
    }
}
