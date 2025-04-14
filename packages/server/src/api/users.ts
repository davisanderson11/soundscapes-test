import { orm } from "~/db"
import { User } from "~/db/entities"
import { authedProcedure, router } from "~/trpc"

export const usersRouter = router({
    me: authedProcedure.query(({ ctx }) => {
        // TODO: check that user exists, maybe in auth middleware?
        return orm.em.findOne(User, ctx.userID)
    })
})
