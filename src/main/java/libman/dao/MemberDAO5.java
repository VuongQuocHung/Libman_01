package libman.dao;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Librarian5;
import libman.model.Member5;
import libman.model.Reader5;

public class MemberDAO5 extends DAO5 {

    public MemberDAO5() throws SQLException {
        super();
    }

    /**
     * Đăng nhập: trả về Reader5 hoặc Librarian5 tùy vai trò (cột type) của tài khoản,
     * Member5 nếu là vai trò khác, hoặc null nếu sai tên tài khoản hoặc mật khẩu.
     * Mật khẩu trong CSDL lưu dạng SHA-256 nên câu truy vấn băm mật khẩu bằng SHA2().
     */
    public Member5 login(String username, String password) throws SQLException {
        String sql = "SELECT m.id, m.username, m.fullName, m.email, m.phone, m.address, "
                + "m.type, m.isActive, m.birthDate, m.note, "
                + "r.readerCode, s.staffCode, s.position, s.startDate, l.schedule "
                + "FROM tblMember5 m "
                + "LEFT JOIN tblReader5 r ON r.tblMember5id = m.id "
                + "LEFT JOIN tblStaff5 s ON s.tblMember5id = m.id "
                + "LEFT JOIN tblLibrarian5 l ON l.tblStaff5Member5id = m.id "
                + "WHERE m.username = ? AND m.password = SHA2(?, 256)";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                // Tạo đúng loại đối tượng theo vai trò của thành viên
                String type = rs.getString("type");
                Member5 member;
                if ("Độc giả".equals(type)) {
                    Reader5 reader = new Reader5();
                    reader.setReaderCode(rs.getString("readerCode"));
                    member = reader;
                } else if ("Nhân viên thư viện".equals(type)) {
                    Librarian5 librarian = new Librarian5();
                    librarian.setStaffCode(rs.getString("staffCode"));
                    librarian.setPosition(rs.getString("position"));
                    librarian.setStartDate(rs.getDate("startDate"));
                    librarian.setSchedule(rs.getString("schedule"));
                    member = librarian;
                } else {
                    member = new Member5();
                }

                // Thông tin chung của thành viên
                member.setId(rs.getInt("id"));
                member.setUsername(rs.getString("username"));
                member.setFullName(rs.getString("fullName"));
                member.setEmail(rs.getString("email"));
                member.setPhone(rs.getString("phone"));
                member.setAddress(rs.getString("address"));
                member.setType(type);
                member.setActive(rs.getBoolean("isActive"));
                member.setBirthDate(rs.getDate("birthDate"));
                member.setNote(rs.getString("note"));
                return member;
            }
        }
    }
}
