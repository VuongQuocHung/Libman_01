package libman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Reader5;
import libman.util.DBUtil;

public class ReaderDAO5 {

    /** Lấy độc giả theo mã độc giả (kèm thông tin thành viên); null nếu không có. */
    public Reader5 getReaderByCode(String readerCode) throws SQLException {
        String sql = "SELECT " + MemberMapper.MEMBER_COLUMNS + ", r.readerCode "
                + "FROM tblReader5 r JOIN tblMember5 m ON m.id = r.id WHERE r.readerCode = ?";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, readerCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Reader5 r = new Reader5();
                MemberMapper.fill(r, rs);
                r.setReaderCode(rs.getString("readerCode"));
                return r;
            }
        }
    }
}
